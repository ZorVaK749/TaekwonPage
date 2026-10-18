package tech.zvk.taekwonpage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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

    @Test
    void migrationsRunAtStartup() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM flyway_schema_history WHERE success", Integer.class)).isEqualTo(1);
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
        assertThat(positions.findById("missing_position")).isEmpty();
    }
}
