package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.BodyToolResponse;
import tech.zvk.taekwonpage.content.persistence.BodyToolRepository;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class BodyToolService {
    private final BodyToolRepository tools;
    private final ContentSourceRepository sources;

    public BodyToolService(BodyToolRepository tools, ContentSourceRepository sources) {
        this.tools = tools;
        this.sources = sources;
    }

    // Internal draft read. This is NOT an educational publication/access policy.
    @Transactional(readOnly = true)
    public Optional<BodyToolResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return tools.findById(id).map(tool -> new BodyToolResponse(
            tool.getId(), tool.getContent().getName(), tool.getContent().getDescription(),
            tool.getContent().getReviewStatus(), sources.findCitationsByContentId(id)));
    }
}
