package tech.zvk.taekwonpage.content.api;

import java.math.BigDecimal;
import java.util.List;

public record PositionResponse(
    String id, String name, String description, String reviewStatus,
    BigDecimal frontPercent, BigDecimal rearPercent,
    BigDecimal frontRotationDeg, BigDecimal rearRotationDeg,
    List<CitationResponse> citations
) {
    public PositionResponse {
        citations = List.copyOf(citations);
    }
}
