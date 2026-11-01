package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.KickResponse;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.content.persistence.KickRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class KickService {
    private final KickRepository kicks;
    private final ContentSourceRepository sources;

    public KickService(KickRepository kicks, ContentSourceRepository sources) {
        this.kicks = kicks;
        this.sources = sources;
    }

    // Internal draft read. This is NOT an educational publication/access policy.
    @Transactional(readOnly = true)
    public Optional<KickResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return kicks.findById(id).map(kick -> new KickResponse(
            kick.getId(), kick.getContent().getName(), kick.getContent().getDescription(),
            kick.getContent().getReviewStatus(), sources.findCitationsByContentId(id)));
    }
}
