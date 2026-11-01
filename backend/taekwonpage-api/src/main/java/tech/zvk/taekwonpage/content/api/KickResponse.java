package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record KickResponse(
    String id, String name, String description, String reviewStatus,
    List<CitationResponse> citations
) {
    public KickResponse {
        citations = List.copyOf(citations);
    }
}
