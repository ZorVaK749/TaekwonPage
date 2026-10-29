package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record TulResponse(
    String id, String name, String description, String reviewStatus,
    Integer movementCount, String initialPositionId,
    boolean sequenceComplete, String sequenceScope,
    List<TulStepResponse> steps, List<CitationResponse> citations
) {
    public TulResponse {
        steps = List.copyOf(steps);
        citations = List.copyOf(citations);
    }
}
