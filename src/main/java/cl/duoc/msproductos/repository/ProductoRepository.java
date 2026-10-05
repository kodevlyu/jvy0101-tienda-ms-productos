package cl.duoc.msproductos.repository;

import cl.duoc.msproductos.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductoRepository extends JpaRepository<Producto, Long> {
}