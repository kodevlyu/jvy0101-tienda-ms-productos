package cl.duoc.msproductos.service;

import cl.duoc.msproductos.exception.RecursoNoEncontradoException;
import cl.duoc.msproductos.model.Categoria;
import cl.duoc.msproductos.model.Producto;
import cl.duoc.msproductos.repository.ProductoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductoService {

    private final ProductoRepository productoRepository;
    private final CategoriaService categoriaService;

    public ProductoService(ProductoRepository productoRepository, CategoriaService categoriaService) {
        this.productoRepository = productoRepository;
        this.categoriaService = categoriaService;
    }

    public Producto crear(Producto producto) {
        producto.setId(null);
        Categoria categoria = categoriaService.buscarPorId(producto.getCategoria().getId());
        producto.setCategoria(categoria);
        return productoRepository.save(producto);
    }

    public List<Producto> listar() {
        return productoRepository.findAll();
    }

    public Producto buscarPorId(Long id) {
        return productoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Producto no encontrado con id " + id));
    }

    public Producto actualizar(Long id, Producto datos) {
        Producto existente = buscarPorId(id);
        existente.setNombre(datos.getNombre());
        existente.setDescripcion(datos.getDescripcion());
        existente.setPrecio(datos.getPrecio());
        existente.setStock(datos.getStock());
        existente.setCategoria(categoriaService.buscarPorId(datos.getCategoria().getId()));
        return productoRepository.save(existente);
    }

    public void eliminar(Long id) {
        productoRepository.delete(buscarPorId(id));
    }
}