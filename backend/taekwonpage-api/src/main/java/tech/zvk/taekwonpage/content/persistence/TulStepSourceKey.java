package tech.zvk.taekwonpage.content.persistence;

import java.io.Serializable;
import java.util.Objects;

public record TulStepSourceKey(String tulId, Integer stepNumber, String citationId) implements Serializable {
    public TulStepSourceKey {
        Objects.requireNonNull(tulId, "tulId");
        Objects.requireNonNull(stepNumber, "stepNumber");
        Objects.requireNonNull(citationId, "citationId");
    }
}
