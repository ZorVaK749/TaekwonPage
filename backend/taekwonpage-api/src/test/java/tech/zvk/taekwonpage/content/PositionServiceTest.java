package tech.zvk.taekwonpage.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import tech.zvk.taekwonpage.content.persistence.PositionRepository;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;

class PositionServiceTest {
    private final PositionRepository repository = mock(PositionRepository.class);
    private final ContentSourceRepository sources = mock(ContentSourceRepository.class);
    private final PositionService service = new PositionService(repository, sources);

    @Test
    void rejectsNoncanonicalIdsBeforeQuerying() {
        for (String id : new String[] {null, "", "UPPERCASE", "con espacio", "x' OR '1'='1", "id\n"}) {
            assertThatThrownBy(() -> service.findById(id)).isInstanceOf(IllegalArgumentException.class);
        }
        verifyNoInteractions(repository, sources);
    }

    @Test
    void missingPositionIsNotInvented() {
        when(repository.findById("missing_position")).thenReturn(Optional.empty());
        assertThat(service.findById("missing_position")).isEmpty();
        verify(repository).findById("missing_position");
        verifyNoInteractions(sources);
    }
}
