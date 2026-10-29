package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.TheoryResponse;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.content.persistence.TheoryContentRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class TheoryService {
    private final TheoryContentRepository theory;
    private final ContentSourceRepository sources;

    public TheoryService(TheoryContentRepository theory, ContentSourceRepository sources) {
        this.theory = theory;
        this.sources = sources;
    }

    // Internal draft read. This is NOT an educational publication/access policy.
    @Transactional(readOnly = true)
    public Optional<TheoryResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return theory.findById(id).map(entry -> new TheoryResponse(
            entry.getId(), entry.getContent().getName(), entry.getContent().getDescription(),
            entry.getContent().getReviewStatus(), sources.findCitationsByContentId(id)));
    }
}
