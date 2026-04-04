package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.SelecaoCreateRequest;
import com.bolao.copa.bolao.api.SelecaoResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/selecoes")
public class SelecaoController {

    private final SelecaoService selecaoService;

    public SelecaoController(SelecaoService selecaoService) {
        this.selecaoService = selecaoService;
    }

    @GetMapping
    public List<SelecaoResponse> list() {
        return selecaoService.list();
    }

    @GetMapping("/{id}")
    public SelecaoResponse getById(@PathVariable Long id) {
        return selecaoService.getById(id);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public SelecaoResponse create(@Valid @RequestBody SelecaoCreateRequest request) {
        return selecaoService.create(request);
    }
}
