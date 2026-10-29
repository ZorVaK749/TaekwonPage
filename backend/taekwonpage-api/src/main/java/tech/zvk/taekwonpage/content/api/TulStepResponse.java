package tech.zvk.taekwonpage.content.api;

import java.util.List;

// One documented step of a draft sequence; unknown counts stay null, never inferred.
public record TulStepResponse(
    Integer stepNumber, String positionId, String description,
    List<String> citationIds
) {
    public TulStepResponse {
        citationIds = List.copyOf(citationIds);
    }
}
