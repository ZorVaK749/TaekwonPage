package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record CombatResponse(
    String id, String name, String description, String reviewStatus,
    List<CitationResponse> citations
) {
    public CombatResponse {
        citations = List.copyOf(citations);
    }
}
