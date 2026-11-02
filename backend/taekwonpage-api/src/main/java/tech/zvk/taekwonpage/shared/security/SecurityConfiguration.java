package tech.zvk.taekwonpage.shared.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.DispatcherType;
import java.io.IOException;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class SecurityConfiguration {
    // C1: JWT local autoemitido. The secret comes from the environment (JWT_SECRET)
    // and is rejected at startup when shorter than 32 bytes.
    @Bean
    LocalJwtService localJwtService(
            @Value("${taekwonpage.security.jwt.secret}") String secret,
            @Value("${taekwonpage.security.jwt.issuer}") String issuer,
            @Value("${taekwonpage.security.jwt.ttl-seconds}") long ttlSeconds) {
        return new LocalJwtService(secret, issuer, Duration.ofSeconds(ttlSeconds));
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, LocalJwtService jwt) throws Exception {
        return http
            .authorizeHttpRequests(access -> access
                // Internal error dispatch must preserve MVC 400/415 instead of becoming 403.
                // A direct HTTP request to /error is still REQUEST and hits denyAll.
                .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                .requestMatchers(HttpMethod.GET, "/actuator/health").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/v1/auth/login").permitAll()
                .requestMatchers("/api/v1/me").authenticated()
                .anyRequest().denyAll())
            .addFilterBefore(new JwtAuthenticationFilter(jwt), UsernamePasswordAuthenticationFilter.class)
            // Stateless bearer API: there is no session cookie to protect with CSRF.
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .requestCache(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable)
            .exceptionHandling(errors -> errors.authenticationEntryPoint(new IdentityEntryPoint()))
            .build();
    }

    // 401 only on the identity read; every other denied route keeps the
    // historical 403, so the deny-all content posture does not change.
    private static final class IdentityEntryPoint implements AuthenticationEntryPoint {
        private static final String ME_PATH = "/api/v1/me";

        @Override
        public void commence(HttpServletRequest request, HttpServletResponse response,
                AuthenticationException auth) throws IOException {
            if (ME_PATH.equals(request.getRequestURI())) {
                response.setHeader(HttpHeaders.WWW_AUTHENTICATE, "Bearer");
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            } else {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            }
        }
    }
}
