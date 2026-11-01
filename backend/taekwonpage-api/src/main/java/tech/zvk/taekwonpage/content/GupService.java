package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.GupResponse;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.content.persistence.GupRepository;

@Service
public class GupService {
    private final GupRepository gups;
    private final ContentSourceRepository sources;

    public GupService(GupRepository gups, ContentSourceRepository sources) {
        this.gups = gups;
        this.sources = sources;
    }

    // Internal draft read of the observed curriculum shape. This is NOT an
    // educational publication policy: an absent curriculum stays absent.
    @Transactional(readOnly = true)
    public Optional<GupResponse> findByNumber(Integer gup) {
        if (gup == null || gup < 1 || gup > 10) {
            throw new IllegalArgumentException("gup must be an integer between 1 and 10");
        }
        return gups.findByNumber(gup).map(entry -> new GupResponse(
            entry.getId(), entry.getNumber(), entry.getContent().getName(),
            entry.getContent().getDescription(), entry.getContent().getReviewStatus(),
            new GupResponse.Requirements(
                gups.findPositionIds(entry.getId()),
                gups.findTheoryIds(entry.getId()),
                gups.findVocabularyIds(entry.getId()),
                gups.findBodyToolIds(entry.getId()),
                gups.findKickIds(entry.getId()),
                gups.findTulIds(entry.getId()),
                gups.findCombatIds(entry.getId())),
            sources.findCitationsByContentId(entry.getId())));
    }
}
