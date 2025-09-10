local ClassSystem = require(script.Parent.ClassSystem)

type Implements<T> = {
    onStart: (self: ComponentClass<T>) -> ();
    onDestroy: (self: ComponentClass<T>) -> ();
}

type Methods<T> = {
    destroy: (self: ComponentClass<T>) -> ();
}

type Props<T> = {
    instance: T;
}

export type ComponentClass<T = Instance> = ClassSystem.Class<Methods<T>, Implements<T>, Props<T>, T>

return {}