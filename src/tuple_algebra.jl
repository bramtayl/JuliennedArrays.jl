import Base.tail


find_tuple(t) = find_tuple(t, 1)
find_tuple(t, n) = begin
    next = find_tuple(tail(t), n + 1)
    if_else(first(t), (n, next...), next)
end
find_tuple(t::Tuple{}, n) = ()

drop_tuple(t::Tuple{A}) where A = first(t)
drop_tuple(t) = t


not(::Val{false}) = Val{true}()
not(::Val{true}) = Val{false}()

is_iterated(::typeof(*)) = Val{true}()
is_iterated(::typeof(:)) = Val{false}()

if_else(switch::Val{false}, new, old) = old
if_else(switch::Val{true}, new, old) = new

get_index(into::Tuple{}, index) = ()
get_index(into, index) = begin
    next = get_index(tail(into), tail(index))
    if_else(first(index), (first(into), next...), next)
end

set_index(old::Tuple{}, new::Tuple{}, switch::Tuple{}) = ()
set_index(old::Tuple{}, new, switch::Tuple{}) = ()
set_index(old, new::Tuple{}, switch) = old
set_index(old, new, switch) =  begin
    first_switch = first(switch)
    if_else(first_switch, first(new), first(old)),
    set_index(
        tail(old),
        if_else(first_switch, tail(new), new),
        tail(switch))...
end

fill_index(old::Tuple{}, new, switch::Tuple{}) = ()
fill_index(old, new, switch) =  begin
    first_switch = first(switch)
    if_else(first_switch, new, first(old)),
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
    if_else(first_switch, first(new), first(old)),
    set_fill_index(
        tail(old),
        if_else(first_switch, tail(new), new),
        tail(switch),
        default)...
end
