module TensorAlgebra

using LinearAlgebra

export Tensor, Covector, VectorSpace, DualSpace, ProductSpace, TensorProduct, spaces, tensors, label, field, degree, dual, domain, ×, ⊗

abstract type AbstractSpace{K,N} end

struct VectorSpace{K,L} <: AbstractSpace{K,1} end

struct DualSpace{K,L} <: AbstractSpace{K,1} end

struct ProductSpace{K,N,S} <: AbstractSpace{K,N} end

abstract type AbstractTensor{K,N} <: AbstractArray{K,N} end

struct Tensor{K,N,D <: AbstractSpace{K}} <: AbstractTensor{K,N}
    array::Array{K,N}
end

const Covector{K,L} = Tensor{K,1,VectorSpace{K,L}}

struct TensorProduct{K,N,S} <: AbstractTensor{K,N}
    scalar::K
    tensors::S
end

field(::AbstractSpace{K}) where {K} = K

field(::AbstractTensor{K}) where {K} = K

field(::Vector{K}) where {K} = K

degree(::AbstractSpace{K,N}) where {K,N} = N

degree(::AbstractTensor{K,N}) where {K,N} = N

spaces(::ProductSpace{K,N,S}) where {K,N,S} = S

label(::Union{VectorSpace{K,L},DualSpace{K,L}}) where {K,L} = L

dual(::VectorSpace{K,L}) where {K,L} = DualSpace{K,L}()

dual(::DualSpace{K,L}) where {K,L} = VectorSpace{K,L}()

dual(ps::ProductSpace) = ProductSpace(dual.(spaces(ps))...)

Covector(::VectorSpace{K,L},a) where {K,L} = Tensor{K,1,VectorSpace{K,L}}(a)

Vector(::VectorSpace{K,L},a) where {K,L} = Tensor{K,1,DualSpace{K,L}}(a)

VectorSpace(L::Symbol,::Type{K}) where {K} = VectorSpace{K,L}()

ProductSpace(args::AbstractSpace{K,1}...) where {K} = 
    ProductSpace{K,length(args),(args...,)}()

Tensor(::D,a::Array{K,N}) where {K,N,D<:AbstractSpace{K,N}} = Tensor{K,N,D}(a)

TensorProduct(args::Tensor{K}...) where {K} = TensorProduct{K,sum(degree.(args)),typeof((args...,))}(one(K),(args...,))

domain(::Tensor{K,N,D}) where {K,N,D} = D()

domain(tp::TensorProduct{K,N,S}) where {K,N,S} = ProductSpace{K,N,domain.(tensors(tp))}()

scalar(::Tensor{K}) where {K} = one(K)

scalar(tp::TensorProduct) = tp.scalar

tensors(t::Tensor) = t

tensors(tp::TensorProduct) = tp.tensors

function (f::Tensor{K,N})(x::Tensor{K,N}) where {K,N}
    dual(domain(f)) === domain(x) || error("Domain mismatch")
    dot(f.array, x.array)
end

(f::Tensor{K,N,D})(x::K) where {K,N,D} = Tensor{K,N,D}(x*f.array)

Base.size(t::Tensor) = size(t.array)

Base.size(t::TensorProduct) = ((size.(t.tensors)...)...,)

Base.getindex(t::Tensor,ix::Vararg{Int}) = getindex(t.array, ix...)

function Base.getindex(tp::TensorProduct,ix::Vararg{Int})
    value = one(field(tp))
    offset = 0
    for (i,tensor) in enumerate(tp.tensors)
        it = degree(tensor) === 1 ? ix[offset+1] : ix[offset+1:offset+degree(tensor)]
        value *= getindex(tensor, it)
        offset += degree(tensor)
    end
    value*scalar(tp)
end

Base.:^(v::AbstractSpace,::typeof(*)) = dual(v)

Base.first(ts::ProductSpace) = first(spaces(ts))

Base.last(ts::ProductSpace) = last(spaces(ts))

Base.in(t::Tensor{K,1}, vs::AbstractSpace{K,1}) where {K} = dual(domain(t)) === vs

Base.:*(x::Number,t::Tensor{K,N,D}) where {K,N,D} = Tensor{K,N,D}(x*t.array)

Base.:*(t::Tensor{K,N,D},x::Number) where {K,N,D} = Tensor{K,N,D}(x*t.array)

Base.:*(x::Number,tp::TensorProduct{K,N,S}) where {K,N,S} = TensorProduct{K,N,S}(x*scalar(tp),tensors(tp))

Base.:*(tp::TensorProduct{K,N,S},x::Number) where {K,N,S} = x*tp

×(vs1::AbstractSpace{K,1},vs2::AbstractSpace{K,1}) where {K} = ProductSpace(vs1,vs2)

×(vs::AbstractSpace{K,1},ts::ProductSpace{K}) where {K} = ProductSpace(vs,spaces(ts)...)

×(ts::ProductSpace{K},vs::AbstractSpace{K,1}) where {K} = ProductSpace(spaces(ts)...,vs)

×(ts1::ProductSpace{K},ts2::ProductSpace{K}) where {K} = ProductSpace((spaces(ts1)..., spaces(ts2)...))

⊗(t1::Tensor{K,R1},t2::Tensor{K,R2}) where {K,R1,R2} = TensorProduct{K,R1+R2,typeof((t1,t2))}(one(K),(t1,t2))

⊗(tp::TensorProduct{K,R1},t::Tensor{K,R2}) where {K,R1,R2} = TensorProduct{K,R1+R2,typeof((tensors(tp)...,t))}(scalar(tp),(tensors(tp)...,t))

⊗(t::Tensor{K,R1},tp::TensorProduct{K,R2}) where {K,R1,R2} = TensorProduct{K,R1+R2,typeof((t,tensors(tp)...))}(scalar(tp),(t,tensors(tp)...))

⊗(t1::TensorProduct{K,R1},t2::TensorProduct{K,R2}) where {K,R1,R2} = TensorProduct{K,R1+R2,typeof((tensors(t1)...,tensors(t2)...))}(scalar(t1)*scalar(t2),(tensors(t1)...,tensors(t2)...))

⊗(t1::AbstractTensor,t2::AbstractTensor,ts::Vararg{<:AbstractTensor}) = TensorProduct(scalar(t1)*scalar(t2),t1⊗t2,ts...)

Base.show(io::IO, ::VectorSpace{K,L}) where {K,L} = print(io, L)

Base.show(io::IO, ::Type{VectorSpace{K,L}}) where {K,L} = print(io, L)

Base.show(io::IO, ::DualSpace{K,L}) where {K,L} = print(io, L, "⃰")

Base.show(io::IO, ::Type{DualSpace{K,L}}) where {K,L} = print(io, L, "⃰")

Base.show(io::IO, ::ProductSpace{K,N,S}) where {K,N,S} = print(io, join(S, " × "))

end # module
