package tech.zvk.taekwonpage.content;

import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.CombatResponse;
import tech.zvk.taekwonpage.content.persistence.CombatTypeRepository;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class CombatService {
    private final CombatTypeRepository combatTypes;
    private final ContentSourceRepository sources;

    public CombatService(CombatTypeRepository combatTypes, ContentSourceRepository sources) {
        this.combatTypes = combatTypes;
        this.sources = sources;
    }

    // Internal draft read of an observed combat modality; no modality is selected or approved here.
    @Transactional(readOnly = true)
    public Optional<CombatResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return combatTypes.findById(id).map(type -> new CombatResponse(
            type.getId(), type.getContent().getName(), type.getContent().getDescription(),
            type.getContent().getReviewStatus(), sources.findCitationsByContentId(id)));
    }
}
