import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/place_order_usecase.dart';
import '../../domain/repositories/marketplace_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();
  @override
  List<Object?> get props => [];
}

class MarketplaceLoadRequested extends MarketplaceEvent {
  final String? category;
  final String? search;
  const MarketplaceLoadRequested({this.category, this.search});
  @override
  List<Object?> get props => [category, search];
}

class ProductDetailRequested extends MarketplaceEvent {
  final String id;
  const ProductDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ProductCreateRequested extends MarketplaceEvent {
  final Map<String, dynamic> data;
  const ProductCreateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class MarketplaceOrderRequested extends MarketplaceEvent {
  final String productId;
  final int quantity;
  const MarketplaceOrderRequested(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}
class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<ProductEntity> products;
  final String? activeCategory;
  const MarketplaceLoaded({required this.products, this.activeCategory});
  @override
  List<Object?> get props => [products, activeCategory];
}

class ProductDetailLoaded extends MarketplaceState {
  final ProductEntity product;
  const ProductDetailLoaded(this.product);
  @override
  List<Object?> get props => [product];
}

class MarketplaceError extends MarketplaceState {
  final String message;
  const MarketplaceError(this.message);
  @override
  List<Object?> get props => [message];
}

class MarketplaceActionSuccess extends MarketplaceState {
  final String message;
  const MarketplaceActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final GetProductsUsecase _getProducts;
  final PlaceOrderUsecase _placeOrder;
  final MarketplaceRepository _repository;

  MarketplaceBloc({
    required GetProductsUsecase getProducts,
    required PlaceOrderUsecase placeOrder,
    required MarketplaceRepository repository,
  })  : _getProducts = getProducts,
        _placeOrder = placeOrder,
        _repository = repository,
        super(MarketplaceInitial()) {
    on<MarketplaceLoadRequested>(_onLoad);
    on<ProductDetailRequested>(_onDetail);
    on<ProductCreateRequested>(_onCreate);
    on<MarketplaceOrderRequested>(_onOrder);
  }

  Future<void> _onLoad(
      MarketplaceLoadRequested event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    final result =
        await _getProducts(category: event.category, search: event.search);
    result.fold(
      (error) => emit(MarketplaceError(error)),
      (products) => emit(
          MarketplaceLoaded(products: products, activeCategory: event.category)),
    );
  }

  Future<void> _onDetail(
      ProductDetailRequested event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    final result = await _repository.getProductById(event.id);
    result.fold(
      (error) => emit(MarketplaceError(error)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }

  Future<void> _onCreate(
      ProductCreateRequested event, Emitter<MarketplaceState> emit) async {
    final result = await _repository.createProduct(event.data);
    result.fold(
      (error) => emit(MarketplaceError(error)),
      (_) => emit(const MarketplaceActionSuccess('Produit mis en ligne')),
    );
  }

  Future<void> _onOrder(
      MarketplaceOrderRequested event, Emitter<MarketplaceState> emit) async {
    final result = await _placeOrder(event.productId, event.quantity);
    result.fold(
      (error) => emit(MarketplaceError(error)),
      (_) => emit(const MarketplaceActionSuccess('Commande passée avec succès !')),
    );
  }
}
