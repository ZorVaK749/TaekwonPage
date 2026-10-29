package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "tul_step")
@IdClass(TulStepKey.class)
public class TulStep {
    @Id
    @Column(name = "tul_id", columnDefinition = "canonical_id")
    private String tulId;
    @Id
    @Column(name = "step_number")
    private Integer stepNumber;
    @Column(name = "position_id", columnDefinition = "canonical_id")
    private String positionId;
    @Column(columnDefinition = "text")
    private String description;

    protected TulStep() { }

    public String getTulId() { return tulId; }
    public Integer getStepNumber() { return stepNumber; }
    public String getPositionId() { return positionId; }
    public String getDescription() { return description; }
}
