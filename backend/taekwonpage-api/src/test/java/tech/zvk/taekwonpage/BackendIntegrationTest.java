package tech.zvk.taekwonpage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import tech.zvk.taekwonpage.content.PositionService;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class BackendIntegrationTest {
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:17.7-alpine");

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired PositionService positions;
    @Autowired ObjectMapper json;

    @Test
    void migrationsRunAtStartup() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM flyway_schema_history WHERE success", Integer.class)).isEqualTo(6);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM content_entry", Integer.class)).isZero();
    }

    @Test
    void healthIsPublicWithoutInternals() throws Exception {
        mvc.perform(get("/actuator/health")).andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("UP"))
            .andExpect(jsonPath("$.components").doesNotExist());
    }

    @Test
    void anonymousRequestsCannotReadContentOrDiagnostics() throws Exception {
        for (String route : new String[] {"/api/v1/positions/test_position", "/api/v1/gups/10",
                "/actuator/env", "/actuator", "/v3/api-docs", "/login"}) {
            mvc.perform(get(route)).andExpect(status().isForbidden());
        }
    }

    @Test
    @WithMockUser(roles = {"ADMIN", "DEVELOPER", "STUDENT"})
    void evenAuthenticatedRolesDoNotBypassPendingAccessPolicy() throws Exception {
        mvc.perform(get("/api/v1/positions/test_position")).andExpect(status().isForbidden());
    }

    @Test
    void writesAndCrossOriginPreflightAreNotOpened() throws Exception {
        mvc.perform(post("/api/v1/positions").contentType("application/json").content("{}"))
            .andExpect(status().isForbidden());
        mvc.perform(options("/api/v1/positions/test_position")
                .header("Origin", "https://untrusted.invalid")
                .header("Access-Control-Request-Method", "GET"))
            .andExpect(status().isForbidden());
    }

    @Test
    @Transactional
    void mapsSyntheticPositionToDtoWithoutFillingUnknownGeometry() {
        jdbc.update("INSERT INTO content_entry(id, content_type, name, description) VALUES (?, 'position', ?, ?)",
            "test_position", "Posición sintética", "Solo prueba técnica");
        jdbc.update("INSERT INTO position(id, front_percent, rear_percent) VALUES (?, 50, 50)", "test_position");
        var position = positions.findById("test_position").orElseThrow();
        assertThat(position.name()).isEqualTo("Posición sintética");
        assertThat(position.frontPercent()).isEqualByComparingTo("50");
        assertThat(position.rearPercent()).isEqualByComparingTo("50");
        assertThat(position.frontRotationDeg()).isNull();
        assertThat(position.rearRotationDeg()).isNull();
        assertThat(position.reviewStatus()).isEqualTo("pending_human_review");
        assertThat(position.citations()).isEmpty();
        assertThat(positions.findById("missing_position")).isEmpty();
    }

    @Test
    @Transactional
    void returnsOnlyOwnedCitationsInStableOrderWithExactCopyAndLocators() {
        insertPosition();
        insertSource("test_source_a", "a".repeat(64));
        insertSource("test_source_b", "b".repeat(64));
        // Insert in reverse ID order to exercise the query's explicit ordering.
        insertCitation("test_citation_z", "test_position", "test_source_a", "a".repeat(64), 12, "10", null);
        insertCitation("test_citation_a", "test_position", "test_source_b", "b".repeat(64), null, null, "Sección sintética");
        jdbc.update("INSERT INTO content_entry(id, content_type, name, description) VALUES ('test_other', 'theory', 'Other', 'Test')");
        jdbc.update("INSERT INTO theory_content(id) VALUES ('test_other')");
        insertCitation("test_citation_other", "test_other", "test_source_a", "a".repeat(64), 3, null, null);

        var citations = positions.findById("test_position").orElseThrow().citations();
        assertThat(citations).extracting(c -> c.id()).containsExactly("test_citation_a", "test_citation_z");
        var sectionOnly = citations.getFirst();
        assertThat(sectionOnly.sourceId()).isEqualTo("test_source_b");
        assertThat(sectionOnly.sourceSha256()).isEqualTo("b".repeat(64));
        assertThat(sectionOnly.pdfPage()).isNull();
        assertThat(sectionOnly.printedPage()).isNull();
        assertThat(sectionOnly.section()).isEqualTo("Sección sintética");
        var located = citations.getLast();
        assertThat(located.sourceId()).isEqualTo("test_source_a");
        assertThat(located.sourceSha256()).isEqualTo("a".repeat(64));
        assertThat(located.pdfPage()).isEqualTo(12);
        assertThat(located.printedPage()).isEqualTo("10");
        assertThat(located.section()).isNull();
        assertThat(located.sourceTitle()).isEqualTo("Documento sintético");
        assertThat(located.sourceOrganization()).isEqualTo("Organización de prueba");
        assertThat(located.sourceAuthor()).isEqualTo("Autor de prueba");
        assertThat(located.sourceEdition()).isEqualTo("Edición de prueba");
        assertThat(located.sourceLanguage()).isEqualTo("es");
        for (var citation : citations) {
            assertThat(citation.reviewStatus()).isEqualTo("pending_human_review");
            assertThat(citation.sourceReviewStatus()).isEqualTo("pending_human_review");
            assertThat(citation.redistributionStatus()).isEqualTo("unknown");
        }
    }

    @Test
    @Transactional
    void missingBibliographyIsNotInferredFromFilenameOrOtherSources() {
        insertPosition();
        insertSource("test_source_a", "a".repeat(64));
        jdbc.update("UPDATE source_document SET title = NULL, organization = NULL, author = NULL, edition = NULL, language = NULL WHERE id = 'test_source_a'");
        insertCitation("test_citation_a", "test_position", "test_source_a", "a".repeat(64), 1, null, null);
        var citation = positions.findById("test_position").orElseThrow().citations().getFirst();
        assertThat(citation.sourceTitle()).isNull();
        assertThat(citation.sourceOrganization()).isNull();
        assertThat(citation.sourceAuthor()).isNull();
        assertThat(citation.sourceEdition()).isNull();
        assertThat(citation.sourceLanguage()).isNull();
    }

    @Test
    @Transactional
    void serializesMetadataWithoutPdfPathsOrInternalNotes() throws Exception {
        insertPosition();
        insertSource("test_source_a", "a".repeat(64));
        insertCitation("test_citation_a", "test_position", "test_source_a", "a".repeat(64), 1, null, null);
        var response = json.readTree(json.writeValueAsString(positions.findById("test_position").orElseThrow()));
        assertThat(response.path("citations").size()).isEqualTo(1);
        assertThat(response.path("citations").get(0).path("sourceTitle").asText()).isEqualTo("Documento sintético");
        assertThat(response.path("citations").get(0).path("sourceSha256").asText()).isEqualTo("a".repeat(64));
        assertThat(response.path("frontRotationDeg").isNull()).isTrue();
        assertThat(response.toString()).doesNotContain("fileReference", "file_reference", "internal_note_marker", "pdf_path_marker");
    }

    @Test
    @Transactional
    @WithMockUser(roles = {"ADMIN", "DEVELOPER"})
    void existingCitedDraftStillCannotBeReadOverHttp() throws Exception {
        insertPosition();
        insertSource("test_source_a", "a".repeat(64));
        insertCitation("test_citation_a", "test_position", "test_source_a", "a".repeat(64), 1, null, null);
        var response = mvc.perform(get("/api/v1/positions/test_position")).andExpect(status().isForbidden()).andReturn();
        assertThat(response.getResponse().getContentAsString()).doesNotContain("test_citation_a", "Documento sintético");
    }

    private void insertPosition() {
        jdbc.update("INSERT INTO content_entry(id, content_type, name, description) VALUES ('test_position', 'position', 'Synthetic', 'Test only')");
        jdbc.update("INSERT INTO position(id) VALUES ('test_position')");
    }

    private void insertSource(String id, String hash) {
        jdbc.update("""
            INSERT INTO source_document(id, sha256, size_bytes, pdf_pages, title, organization, author,
                edition, language, file_reference, notes)
            VALUES (?, ?, 100, 20, 'Documento sintético', 'Organización de prueba', 'Autor de prueba',
                'Edición de prueba', 'es', ?, 'internal_note_marker')
            """, id, hash, "local/pdf_path_marker/" + id + ".pdf");
    }

    private void insertCitation(String id, String contentId, String sourceId, String hash,
                                Integer page, String printedPage, String section) {
        jdbc.update("""
            INSERT INTO content_source(id, content_id, source_id, source_sha256, pdf_page, printed_page, section, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'internal_note_marker')
            """, id, contentId, sourceId, hash, page, printedPage, section);
    }
}
