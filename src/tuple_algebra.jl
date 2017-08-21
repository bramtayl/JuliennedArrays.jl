import Base.tail

not(::Val{false}) = Val{true}()
not(::Val{true}) = Val{false}()

is_iterated(::typeof(*)) = Val{true}()
is_iterated(::typeof(:)) = Val{false}()

if_else(switch::Val{false}, old, new) = old
if_else(switch::Val{true}, old, new) = new

get_index(into::Tuple{}, index) = ()
get_index(into, index) = begin
    next = get_index(tail(into), tail(index))
    if_else(first(index), next, (first(into), next...))
end

set_index(old::Tuple{}, new::Tuple{}, switch::Tuple{}) = ()
set_index(old::Tuple{}, new, switch::Tuple{}) = ()
set_index(old, new::Tuple{}, switch) = old
set_index(old, new, switch) =  begin
    first_switch = first(switch)
    if_else(first_switch, first(old), first(new)),
    set_index(
        tail(old),
        if_else(first_switch, new, tail(new)),
        tail(switch))...
end

fill_index(old::Tuple{}, new, switch::Tuple{}) = ()
fill_index(old, new, switch) =  begin
    first_switch = first(switch)
    if_else(first_switch, first(old), new),
    fill_index(
        tail(old),
        new,
        tail(switch))...
end

set_fill_index(old::Tuple{}, new::Tuple{}, switch::Tuple{}, default) = ()
set_fill_index(old::Tuple{}, new, switch::Tuple{}, default) = ()
set_fill_index(old, new::Tuple{}, switch, default) = fill_index(old, default, switch)
set_fill_index(old, new, switch, default) =  begin
    first_switch = first(switch)
    if_else(first_switch, first(old), first(new)),
    set_fill_index(
        tail(old),
        if_else(first_switch, new, tail(new)),
        tail(switch),
        default)...
end
