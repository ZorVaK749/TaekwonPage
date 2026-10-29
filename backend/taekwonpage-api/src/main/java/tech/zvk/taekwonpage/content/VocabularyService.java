package tech.zvk.taekwonpage.content;

import java.util.Arrays;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.VocabularyResponse;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.content.persistence.VocabularyRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class VocabularyService {
    private final VocabularyRepository vocabulary;
    private final ContentSourceRepository sources;

    public VocabularyService(VocabularyRepository vocabulary, ContentSourceRepository sources) {
        this.vocabulary = vocabulary;
        this.sources = sources;
    }

    // Internal draft read. This is NOT an educational publication/access policy.
    @Transactional(readOnly = true)
    public Optional<VocabularyResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return vocabulary.findById(id).map(entry -> new VocabularyResponse(
            entry.getId(), entry.getContent().getName(), entry.getContent().getDescription(),
            entry.getContent().getReviewStatus(), entry.getTranslation(),
            Arrays.stream(entry.getAliases()).toList(), sources.findCitationsByContentId(id)));
    }
}
