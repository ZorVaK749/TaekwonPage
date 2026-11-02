package tech.zvk.taekwonpage.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;
import tech.zvk.taekwonpage.identity.AppUser;
import tech.zvk.taekwonpage.identity.AppUserRepository;

class AuthServiceTest {
    @Test
    void unknownAccountsStillPerformPasswordVerification() {
        var users = mock(AppUserRepository.class);
        var passwords = mock(PasswordEncoder.class);
        when(passwords.encode(anyString())).thenReturn("dummy-hash");
        when(users.findByUsername("ghost")).thenReturn(Optional.empty());
        var auth = new AuthService(users, passwords);

        assertThat(auth.authenticate("ghost", "password")).isEmpty();
        verify(passwords).matches("password", "dummy-hash");
    }

    @Test
    void disabledAccountsVerifyTheDummyHashEvenIfItMatches() {
        var users = mock(AppUserRepository.class);
        var passwords = mock(PasswordEncoder.class);
        var user = mock(AppUser.class);
        when(passwords.encode(anyString())).thenReturn("dummy-hash");
        when(passwords.matches("password", "dummy-hash")).thenReturn(true);
        when(users.findByUsername("alice")).thenReturn(Optional.of(user));
        when(user.enabled()).thenReturn(false);
        var auth = new AuthService(users, passwords);

        assertThat(auth.authenticate("alice", "password")).isEmpty();
        verify(passwords).matches("password", "dummy-hash");
        verify(user, never()).passwordHash();
    }

    @Test
    void enabledAccountsVerifyTheirStoredHashOnce() {
        var users = mock(AppUserRepository.class);
        var passwords = mock(PasswordEncoder.class);
        var user = mock(AppUser.class);
        when(users.findByUsername("alice")).thenReturn(Optional.of(user));
        when(user.enabled()).thenReturn(true);
        when(user.passwordHash()).thenReturn("stored-hash");
        var auth = new AuthService(users, passwords);

        assertThat(auth.authenticate("alice", "wrong-password")).isEmpty();
        verify(passwords).matches("wrong-password", "stored-hash");
    }
}
