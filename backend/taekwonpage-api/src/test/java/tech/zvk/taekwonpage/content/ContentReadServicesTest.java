package tech.zvk.taekwonpage.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import tech.zvk.taekwonpage.content.persistence.BodyToolRepository;
import tech.zvk.taekwonpage.content.persistence.ContentEntry;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.content.persistence.TheoryContentRepository;
import tech.zvk.taekwonpage.content.persistence.Tul;
import tech.zvk.taekwonpage.content.persistence.TulRepository;
import tech.zvk.taekwonpage.content.persistence.TulStep;
import tech.zvk.taekwonpage.content.persistence.TulStepRepository;
import tech.zvk.taekwonpage.content.persistence.TulStepSource;
import tech.zvk.taekwonpage.content.persistence.TulStepSourceRepository;
import tech.zvk.taekwonpage.content.persistence.Vocabulary;
import tech.zvk.taekwonpage.content.persistence.VocabularyRepository;

// Same rules for every draft read service: canonical IDs first, absence never invented.
class ContentReadServicesTest {
    private static final String[] INVALID_IDS =
        {null, "", "UPPERCASE", "con espacio", "x' OR '1'='1", "id\n"};

    private final TheoryContentRepository theory = mock(TheoryContentRepository.class);
    private final VocabularyRepository vocabulary = mock(VocabularyRepository.class);
    private final BodyToolRepository tools = mock(BodyToolRepository.class);
    private final TulRepository tuls = mock(TulRepository.class);
    private final TulStepRepository steps = mock(TulStepRepository.class);
    private final TulStepSourceRepository stepSources = mock(TulStepSourceRepository.class);
    private final ContentSourceRepository sources = mock(ContentSourceRepository.class);

    @Test
    void rejectsNoncanonicalIdsBeforeQueryingAnySubtype() {
        for (String id : INVALID_IDS) {
            assertThatThrownBy(() -> new TheoryService(theory, sources).findById(id))
                .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> new VocabularyService(vocabulary, sources).findById(id))
                .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> new BodyToolService(tools, sources).findById(id))
                .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> new TulService(tuls, steps, stepSources, sources).findById(id))
                .isInstanceOf(IllegalArgumentException.class);
        }
        verifyNoInteractions(theory, vocabulary, tools, tuls, steps, stepSources, sources);
    }

    @Test
    void missingEntriesAreNeverInvented() {
        when(theory.findById("missing_theory")).thenReturn(Optional.empty());
        when(vocabulary.findById("missing_vocabulary")).thenReturn(Optional.empty());
        when(tools.findById("missing_tool")).thenReturn(Optional.empty());
        when(tuls.findById("missing_tul")).thenReturn(Optional.empty());
        assertThat(new TheoryService(theory, sources).findById("missing_theory")).isEmpty();
        assertThat(new VocabularyService(vocabulary, sources).findById("missing_vocabulary")).isEmpty();
        assertThat(new BodyToolService(tools, sources).findById("missing_tool")).isEmpty();
        assertThat(new TulService(tuls, steps, stepSources, sources).findById("missing_tul")).isEmpty();
        verify(theory).findById("missing_theory");
        verify(vocabulary).findById("missing_vocabulary");
        verify(tools).findById("missing_tool");
        verify(tuls).findById("missing_tul");
        verifyNoInteractions(sources);
    }

    @Test
    void tulStepsCarryTheirOwnCitationIdsInStepOrderWithoutCompletingTheSequence() {
        var content = mock(ContentEntry.class);
        when(content.getName()).thenReturn("Saju sintético");
        when(content.getDescription()).thenReturn("Solo prueba técnica");
        when(content.getReviewStatus()).thenReturn("pending_human_review");
        var tul = mock(Tul.class);
        when(tul.getId()).thenReturn("test_tul");
        when(tul.getContent()).thenReturn(content);
        when(tul.getMovementCount()).thenReturn(2);
        when(tul.getInitialPositionId()).thenReturn(null);
        when(tul.isSequenceComplete()).thenReturn(false);
        when(tul.getSequenceScope()).thenReturn(" alcance parcial ");
        when(tuls.findById("test_tul")).thenReturn(Optional.of(tul));

        var first = mock(TulStep.class);
        when(first.getStepNumber()).thenReturn(1);
        when(first.getPositionId()).thenReturn("narani_junbi_sogi");
        when(first.getDescription()).thenReturn("Primer paso sintético");
        var second = mock(TulStep.class);
        when(second.getStepNumber()).thenReturn(2);
        when(second.getPositionId()).thenReturn("gunnun_sogi");
        when(second.getDescription()).thenReturn("Segundo paso sintético");
        when(steps.findByTulIdOrderByStepNumberAsc("test_tul")).thenReturn(List.of(first, second));

        // The repository query orders by (step_number, citation_id); the service only groups.
        var linkOneA = mock(TulStepSource.class);
        when(linkOneA.getStepNumber()).thenReturn(1);
        when(linkOneA.getCitationId()).thenReturn("citation_step_one_a");
        var linkOneB = mock(TulStepSource.class);
        when(linkOneB.getStepNumber()).thenReturn(1);
        when(linkOneB.getCitationId()).thenReturn("citation_step_one_b");
        var linkTwo = mock(TulStepSource.class);
        when(linkTwo.getStepNumber()).thenReturn(2);
        when(linkTwo.getCitationId()).thenReturn("citation_step_two");
        when(stepSources.findByTulIdOrderByStepNumberAscCitationIdAsc("test_tul"))
            .thenReturn(List.of(linkOneA, linkOneB, linkTwo));
        when(sources.findCitationsByContentId("test_tul")).thenReturn(List.of());

        var response = new TulService(tuls, steps, stepSources, sources).findById("test_tul").orElseThrow();
        assertThat(response.movementCount()).isEqualTo(2);
        assertThat(response.sequenceComplete()).isFalse();
        assertThat(response.sequenceScope()).isEqualTo(" alcance parcial ");
        assertThat(response.initialPositionId()).isNull();
        assertThat(response.steps()).extracting(step -> step.stepNumber()).containsExactly(1, 2);
        assertThat(response.steps().getFirst().citationIds())
            .containsExactly("citation_step_one_a", "citation_step_one_b");
        assertThat(response.steps().getLast().citationIds()).containsExactly("citation_step_two");
        assertThat(response.citations()).isEmpty();
    }

    @Test
    void vocabularyTranslationAndAliasesAreReadAsObserved() {
        var content = mock(ContentEntry.class);
        when(content.getName()).thenReturn("Dobok");
        when(content.getDescription()).thenReturn("Solo prueba técnica");
        when(content.getReviewStatus()).thenReturn("pending_human_review");
        var entry = mock(Vocabulary.class);
        when(entry.getId()).thenReturn("test_vocabulary");
        when(entry.getContent()).thenReturn(content);
        when(entry.getTranslation()).thenReturn("Uniforme");
        when(entry.getAliases()).thenReturn(new String[] {"dobok_alias"});
        when(vocabulary.findById("test_vocabulary")).thenReturn(Optional.of(entry));
        when(sources.findCitationsByContentId("test_vocabulary")).thenReturn(List.of());

        var response = new VocabularyService(vocabulary, sources).findById("test_vocabulary").orElseThrow();
        assertThat(response.translation()).isEqualTo("Uniforme");
        assertThat(response.aliases()).containsExactly("dobok_alias");
    }
}
