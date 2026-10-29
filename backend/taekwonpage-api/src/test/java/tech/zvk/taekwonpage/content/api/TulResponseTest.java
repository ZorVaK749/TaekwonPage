package tech.zvk.taekwonpage.content.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class TulResponseTest {
    private final CitationResponse citation = new CitationResponse("test_citation", "test_source",
        "a".repeat(64), null, null, null, null, null, 1, null, null,
        "pending_human_review", "pending_human_review", "unknown");
    private final TulStepResponse step = new TulStepResponse(1, "narani_junbi_sogi",
        "Primer paso sintético", List.of("test_citation"));

    @Test
    void stepAndCitationCollectionsAreDefensiveImmutableCopies() {
        var steps = new ArrayList<>(List.of(step));
        var citations = new ArrayList<>(List.of(citation));
        var dto = new TulResponse("test_tul", "Synthetic", "Test", "pending_human_review",
            2, null, false, "partial scope", steps, citations);
        steps.clear();
        citations.clear();
        assertThat(dto.steps()).containsExactly(step);
        assertThat(dto.citations()).containsExactly(citation);
        assertThatThrownBy(() -> dto.steps().clear()).isInstanceOf(UnsupportedOperationException.class);
        assertThatThrownBy(() -> dto.citations().clear()).isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void missingCollectionsCannotSilentlyBecomeEmptyLists() {
        assertThatThrownBy(() -> new TulResponse("test_tul", "Synthetic", "Test", "pending_human_review",
            null, null, false, null, null, List.of())).isInstanceOf(NullPointerException.class);
        assertThatThrownBy(() -> new TulResponse("test_tul", "Synthetic", "Test", "pending_human_review",
            null, null, false, null, List.of(), null)).isInstanceOf(NullPointerException.class);
    }

    @Test
    void stepCitationIdsAreCopied() {
        var ids = new ArrayList<>(List.of("test_citation"));
        var dto = new TulStepResponse(1, "narani_junbi_sogi", "Primer paso sintético", ids);
        ids.clear();
        assertThat(dto.citationIds()).containsExactly("test_citation");
        assertThatThrownBy(() -> dto.citationIds().clear()).isInstanceOf(UnsupportedOperationException.class);
    }
}
