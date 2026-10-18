package tech.zvk.taekwonpage.content.persistence;

import java.math.BigDecimal;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "position")
public class Position {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id", insertable = false, updatable = false)
    private ContentEntry content;
    @Column(name = "front_percent", columnDefinition = "numeric")
    private BigDecimal frontPercent;
    @Column(name = "rear_percent", columnDefinition = "numeric")
    private BigDecimal rearPercent;
    @Column(name = "front_rotation_deg", columnDefinition = "numeric")
    private BigDecimal frontRotationDeg;
    @Column(name = "rear_rotation_deg", columnDefinition = "numeric")
    private BigDecimal rearRotationDeg;

    protected Position() { }

    public String getId() { return id; }
    public ContentEntry getContent() { return content; }
    public BigDecimal getFrontPercent() { return frontPercent; }
    public BigDecimal getRearPercent() { return rearPercent; }
    public BigDecimal getFrontRotationDeg() { return frontRotationDeg; }
    public BigDecimal getRearRotationDeg() { return rearRotationDeg; }
}
