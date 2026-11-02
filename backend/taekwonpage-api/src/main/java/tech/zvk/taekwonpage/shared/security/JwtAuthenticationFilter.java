package tech.zvk.taekwonpage.shared.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

// Accepts only a Bearer token this server issued. Any failure keeps the
// request anonymous: the entry point then answers 401 on identity routes and
// the historical 403 everywhere else.
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final LocalJwtService jwt;

    public JwtAuthenticationFilter(LocalJwtService jwt) {
        this.jwt = jwt;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        // Multiple credentials are ambiguous; never choose one by header ordering.
        var headers = request.getHeaders(HttpHeaders.AUTHORIZATION);
        if (headers.hasMoreElements()) {
            headers.nextElement();
            if (headers.hasMoreElements()) {
                SecurityContextHolder.clearContext();
                chain.doFilter(request, response);
                return;
            }
        }
        if (header != null && header.length() > 7 && header.regionMatches(true, 0, "Bearer ", 0, 7)) {
            try {
                var claims = jwt.parse(header.substring(7));
                var authorities = claims.roles().stream().map(SimpleGrantedAuthority::new).toList();
                var principal = new AuthenticatedUser(claims.id(), claims.username(), claims.roles());
                var authentication = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (InvalidJwtException rejected) {
                SecurityContextHolder.clearContext();
                // Stay anonymous; the reason is never exposed to the client.
            }
        }
        chain.doFilter(request, response);
    }
}
