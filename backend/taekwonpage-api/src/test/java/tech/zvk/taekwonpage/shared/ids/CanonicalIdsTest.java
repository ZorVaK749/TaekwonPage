package tech.zvk.taekwonpage.shared.ids;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class CanonicalIdsTest {
    @Test
    void acceptsTheSameShapeAsTheDatabaseDomain() {
        for (String id : new String[] {"a", "test_position", "gup_10", "saju_jirugi", "yop_makgi"}) {
            assertThat(CanonicalIds.isValid(id)).isTrue();
            assertThat(CanonicalIds.requireValid(id)).isEqualTo(id);
        }
    }

    @Test
    void rejectsAnythingTheDatabaseDomainWouldReject() {
        for (String id : new String[] {null, "", "UPPERCASE", "con espacio", "_leading", "trailing_",
            "double__underscore", "1leading", "x' OR '1'='1", "id\n"}) {
            assertThat(CanonicalIds.isValid(id)).isFalse();
            assertThatThrownBy(() -> CanonicalIds.requireValid(id))
                .isInstanceOf(IllegalArgumentException.class);
        }
    }
}
