package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record BodyToolResponse(
    String id, String name, String description, String reviewStatus,
    List<CitationResponse> citations
) {
    public BodyToolResponse {
        citations = List.copyOf(citations);
    }
}
