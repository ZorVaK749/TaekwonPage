package tech.zvk.taekwonpage.content.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.content.BodyToolService;
import tech.zvk.taekwonpage.content.TheoryService;
import tech.zvk.taekwonpage.content.TulService;
import tech.zvk.taekwonpage.content.VocabularyService;

// Controller behavior in isolation; real HTTP security is tested separately, never disabled.
class ContentControllersTest {
    private final TheoryService theory = mock(TheoryService.class);
    private final VocabularyService vocabulary = mock(VocabularyService.class);
    private final BodyToolService tools = mock(BodyToolService.class);
    private final TulService tuls = mock(TulService.class);

    @Test
    void missingDraftsMapToNotFoundOnEveryRoute() {
        when(theory.findById("missing_theory")).thenReturn(Optional.empty());
        when(vocabulary.findById("missing_vocabulary")).thenReturn(Optional.empty());
        when(tools.findById("missing_tool")).thenReturn(Optional.empty());
        when(tuls.findById("missing_tul")).thenReturn(Optional.empty());
        assertThat(new TheoryController(theory).findById("missing_theory").getStatusCode())
            .isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(new VocabularyController(vocabulary).findById("missing_vocabulary").getStatusCode())
            .isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(new BodyToolController(tools).findById("missing_tool").getStatusCode())
            .isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(new TulController(tuls).findById("missing_tul").getStatusCode())
            .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void malformedIdsNeverReachAnyService() {
        assertThatThrownBy(() -> new TheoryController(theory).findById("UPPERCASE"))
            .isInstanceOfSatisfying(ResponseStatusException.class,
                error -> assertThat(error.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThatThrownBy(() -> new VocabularyController(vocabulary).findById("con espacio"))
            .isInstanceOfSatisfying(ResponseStatusException.class,
                error -> assertThat(error.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThatThrownBy(() -> new BodyToolController(tools).findById("x' OR '1'='1"))
            .isInstanceOfSatisfying(ResponseStatusException.class,
                error -> assertThat(error.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThatThrownBy(() -> new TulController(tuls).findById(null))
            .isInstanceOfSatisfying(ResponseStatusException.class,
                error -> assertThat(error.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        verifyNoInteractions(theory, vocabulary, tools, tuls);
    }

    @Test
    void controllersReturnTheServiceDtoNotJpaEntities() {
        var theoryDto = new TheoryResponse("test_theory", "Synthetic", "Test", "pending_human_review", List.of());
        when(theory.findById("test_theory")).thenReturn(Optional.of(theoryDto));
        assertThat(new TheoryController(theory).findById("test_theory").getBody()).isSameAs(theoryDto);

        var tulDto = new TulResponse("test_tul", "Synthetic", "Test", "pending_human_review",
            2, null, false, "partial scope", List.of(), List.of());
        when(tuls.findById("test_tul")).thenReturn(Optional.of(tulDto));
        assertThat(new TulController(tuls).findById("test_tul").getBody()).isSameAs(tulDto);
    }
}
