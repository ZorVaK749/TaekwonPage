package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

// Citation link of a single step; the citation row itself lives in content_source.
@Entity
@Immutable
@Table(name = "tul_step_source")
@IdClass(TulStepSourceKey.class)
public class TulStepSource {
    @Id
    @Column(name = "tul_id", columnDefinition = "canonical_id")
    private String tulId;
    @Id
    @Column(name = "step_number")
    private Integer stepNumber;
    @Id
    @Column(name = "citation_id", columnDefinition = "canonical_id")
    private String citationId;

    protected TulStepSource() { }

    public String getTulId() { return tulId; }
    public Integer getStepNumber() { return stepNumber; }
    public String getCitationId() { return citationId; }
}
