package tech.zvk.taekwonpage.content;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tech.zvk.taekwonpage.content.api.TulResponse;
import tech.zvk.taekwonpage.content.api.TulStepResponse;
import tech.zvk.taekwonpage.content.persistence.ContentSourceRepository;
import tech.zvk.taekwonpage.content.persistence.TulRepository;
import tech.zvk.taekwonpage.content.persistence.TulStepRepository;
import tech.zvk.taekwonpage.content.persistence.TulStepSourceRepository;
import tech.zvk.taekwonpage.shared.ids.CanonicalIds;

@Service
public class TulService {
    private final TulRepository tuls;
    private final TulStepRepository steps;
    private final TulStepSourceRepository stepSources;
    private final ContentSourceRepository sources;

    public TulService(TulRepository tuls, TulStepRepository steps,
                      TulStepSourceRepository stepSources, ContentSourceRepository sources) {
        this.tuls = tuls;
        this.steps = steps;
        this.stepSources = stepSources;
        this.sources = sources;
    }

    // Internal draft read of a TUL or partial exercise. Unknown movement counts and
    // incomplete sequences are returned as observed, never completed here.
    @Transactional(readOnly = true)
    public Optional<TulResponse> findById(String id) {
        CanonicalIds.requireValid(id);
        return tuls.findById(id).map(tul -> new TulResponse(
            tul.getId(), tul.getContent().getName(), tul.getContent().getDescription(),
            tul.getContent().getReviewStatus(), tul.getMovementCount(), tul.getInitialPositionId(),
            tul.isSequenceComplete(), tul.getSequenceScope(),
            stepsWithCitations(id), sources.findCitationsByContentId(id)));
    }

    private List<TulStepResponse> stepsWithCitations(String tulId) {
        Map<Integer, List<String>> byStep = new LinkedHashMap<>();
        for (var link : stepSources.findByTulIdOrderByStepNumberAscCitationIdAsc(tulId)) {
            byStep.computeIfAbsent(link.getStepNumber(), key -> new ArrayList<>())
                .add(link.getCitationId());
        }
        return steps.findByTulIdOrderByStepNumberAsc(tulId).stream()
            .map(step -> new TulStepResponse(step.getStepNumber(), step.getPositionId(),
                step.getDescription(), byStep.getOrDefault(step.getStepNumber(), List.of())))
            .toList();
    }
}
