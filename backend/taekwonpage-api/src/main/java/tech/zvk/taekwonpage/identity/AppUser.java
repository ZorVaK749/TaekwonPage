package tech.zvk.taekwonpage.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Set;

// Local account row. The password hash never leaves the service layer: no API
// response maps this entity directly.
@Entity
@Table(name = "app_user")
public class AppUser {
    @Id
    @Column(name = "id", columnDefinition = "canonical_id", nullable = false, updatable = false)
    private String id;

    @Column(name = "username", columnDefinition = "text", nullable = false, updatable = false)
    private String username;

    @Column(name = "password_hash", columnDefinition = "text", nullable = false)
    private String passwordHash;

    @Column(name = "enabled", nullable = false)
    private boolean enabled;

    @Column(name = "created_at", columnDefinition = "timestamptz", nullable = false, updatable = false)
    private Instant createdAt;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "user_role",
        joinColumns = @JoinColumn(name = "user_id", columnDefinition = "canonical_id"),
        inverseJoinColumns = @JoinColumn(name = "role_name", columnDefinition = "text"))
    private Set<Role> roles = new LinkedHashSet<>();

    protected AppUser() {
        // JPA
    }

    public String id() {
        return id;
    }

    public String username() {
        return username;
    }

    public String passwordHash() {
        return passwordHash;
    }

    public boolean enabled() {
        return enabled;
    }

    public Instant createdAt() {
        return createdAt;
    }

    public Set<Role> roles() {
        return roles;
    }
}
