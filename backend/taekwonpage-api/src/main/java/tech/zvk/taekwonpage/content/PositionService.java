package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.PositionResponse;
import tech.zvk.taekwonpage.content.persistence.PositionRepository;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class PositionService {
    private final PositionRepository positions;
    private final ContentSourceRepository sources;

    public PositionService(PositionRepository positions, ContentSourceRepository sources) {
        this.positions = positions;
        this.sources = sources;
    }

    // Internal draft read. This is NOT an educational publication/access policy.
    @Transactional(readOnly = true)
    public Optional<PositionResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return positions.findById(id).map(position -> new PositionResponse(
            position.getId(), position.getContent().getName(), position.getContent().getDescription(),
            position.getContent().getReviewStatus(), position.getFrontPercent(), position.getRearPercent(),
            position.getFrontRotationDeg(), position.getRearRotationDeg(), sources.findCitationsByContentId(id)));
    }
}
