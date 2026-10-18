package tech.zvk.taekwonpage.content.api;

import java.math.BigDecimal;

public record PositionResponse(
    String id, String name, String description, String reviewStatus,
    BigDecimal frontPercent, BigDecimal rearPercent,
    BigDecimal frontRotationDeg, BigDecimal rearRotationDeg
) { }
