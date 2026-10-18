package tech.zvk.taekwonpage.content.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.Optional;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import tech.zvk.taekwonpage.content.PositionService;

// Controller behavior in isolation; real HTTP security is tested separately, never disabled.
class PositionControllerTest {
    private final PositionService service = mock(PositionService.class);
    private final PositionController controller = new PositionController(service);

    @Test
    void mapsMissingResultToNotFound() {
        when(service.findById("missing_position")).thenReturn(Optional.empty());
        assertThat(controller.findById("missing_position").getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void returnsDtoNotJpaEntity() {
        var dto = new PositionResponse("test_position", "Synthetic", "Test", "pending_human_review",
            null, null, null, null, List.of());
        when(service.findById("test_position")).thenReturn(Optional.of(dto));
        assertThat(controller.findById("test_position").getBody()).isSameAs(dto);
    }

    @Test
    void malformedIdNeverReachesService() {
        assertThatThrownBy(() -> controller.findById("UPPERCASE"))
            .isInstanceOfSatisfying(ResponseStatusException.class,
                error -> assertThat(error.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        verifyNoInteractions(service);
    }
}
