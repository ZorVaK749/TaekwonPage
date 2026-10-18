package tech.zvk.taekwonpage.content.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class PositionResponseTest {
    @Test
    void citationCollectionIsADefensiveImmutableCopy() {
        var citation = new CitationResponse("test_citation", "test_source", "a".repeat(64),
            null, null, null, null, null, 1, null, null, "pending_human_review", "pending_human_review", "unknown");
        var original = new ArrayList<>(List.of(citation));
        var dto = new PositionResponse("test_position", "Synthetic", "Test", "pending_human_review",
            null, null, null, null, original);
        original.clear();
        assertThat(dto.citations()).containsExactly(citation);
        assertThatThrownBy(() -> dto.citations().clear()).isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void missingCitationCollectionCannotSilentlyBecomeAnEmptyList() {
        assertThatThrownBy(() -> new PositionResponse("test_position", "Synthetic", "Test", "pending_human_review",
            null, null, null, null, null)).isInstanceOf(NullPointerException.class);
    }
}
