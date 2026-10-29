package tech.zvk.taekwonpage.content.persistence;

import java.io.Serializable;
import java.util.Objects;

public record TulStepKey(String tulId, Integer stepNumber) implements Serializable {
    public TulStepKey {
        Objects.requireNonNull(tulId, "tulId");
        Objects.requireNonNull(stepNumber, "stepNumber");
    }
}
