package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.JogoCreateRequest;
import com.bolao.copa.bolao.api.JogoResponse;
import com.bolao.copa.bolao.api.ResultadoOficialRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/jogos")
public class JogoController {

    private final JogoService jogoService;

    public JogoController(JogoService jogoService) {
        this.jogoService = jogoService;
    }

    @GetMapping
    public List<JogoResponse> list() {
        return jogoService.list();
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public JogoResponse create(@Valid @RequestBody JogoCreateRequest request) {
        return jogoService.create(request);
    }

    @PatchMapping("/{id}/resultado-oficial")
    @PreAuthorize("hasRole('ADMIN')")
    public JogoResponse registrarResultado(
            @PathVariable Long id,
            @Valid @RequestBody ResultadoOficialRequest request) {
        return jogoService.registrarResultadoOficial(id, request);
    }
}
