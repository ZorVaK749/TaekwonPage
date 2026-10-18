package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.PositionResponse;
import tech.zvk.taekwonpage.content.persistence.PositionRepository;

@Service
public class PositionService {
    private final PositionRepository positions;

    public PositionService(PositionRepository positions) {
        this.positions = positions;
    }

    // Internal draft read. This is NOT an educational publication/access policy.
    @Transactional(readOnly = true)
    public Optional<PositionResponse> findById(String id) {
        if (id == null || !id.matches("[a-z][a-z0-9]*(_[a-z0-9]+)*")) {
            throw new IllegalArgumentException("Invalid canonical ID");
        }
        return positions.findById(id).map(position -> new PositionResponse(
            position.getId(), position.getContent().getName(), position.getContent().getDescription(),
            position.getContent().getReviewStatus(), position.getFrontPercent(), position.getRearPercent(),
            position.getFrontRotationDeg(), position.getRearRotationDeg()));
    }
}
