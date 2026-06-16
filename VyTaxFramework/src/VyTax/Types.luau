export type Maid = {
	new: (self: Maid) -> Maid,
	GiveTask: (self: Maid, task: any) -> Maid,
	DoCleaning: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
}

export type SignalConnection = {
	Connected: boolean,
	Disconnect: (self: SignalConnection) -> (),
	Destroy: (self: SignalConnection) -> (),
}

export type Signal<T...> = {
	new: <T...>(self: Signal<T...>) -> Signal<T...>,
	Connect: (self: Signal<T...>, callback: (...T...) -> ()) -> SignalConnection,
	Once: (self: Signal<T...>, callback: (...T...) -> ()) -> SignalConnection,
	Wait: (self: Signal<T...>) -> (...T...),
	Fire: (self: Signal<T...>, ...T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

export type NetworkEvent = {
	Name: string,
	Remote: RemoteEvent | RemoteFunction,
	Fire: (self: NetworkEvent, ...any) -> (),
	FireAllClients: (self: NetworkEvent, ...any) -> (),
	FireClient: (self: NetworkEvent, player: Player, ...any) -> (),
	Connect: (self: NetworkEvent, callback: (...any) -> ()) -> SignalConnection,
	Wait: (self: NetworkEvent) -> (...any),
	Destroy: (self: NetworkEvent) -> (),
}

export type Service = {
	Name: string,
	_init: (self: Service) -> (),
	_start: (self: Service) -> (),
	Destroy: (self: Service) -> (),
}

export type Controller = {
	Name: string,
	Player: Player?,
	_init: (self: Controller) -> (),
	_start: (self: Controller) -> (),
	Destroy: (self: Controller) -> (),
}

export type Component = {
	Name: string,
	Instance: Instance,
	_init: (self: Component) -> (),
	_start: (self: Component) -> (),
	Destroy: (self: Component) -> (),
}

export type VyTaxLoader = {
	_services: { [string]: Service },
	_controllers: { [string]: Controller },
	_components: { [string]: Component },
	_loaded: boolean,
	_started: boolean,
	_maid: Maid,
	LoadServices: (self: VyTaxLoader, ...folders: Folder) -> (),
	LoadControllers: (self: VyTaxLoader, ...folders: Folder) -> (),
	LoadComponents: (self: VyTaxLoader, ...folders: Folder) -> (),
	GetService: (self: VyTaxLoader, name: string) -> Service?,
	GetController: (self: VyTaxLoader, name: string) -> Controller?,
	GetComponent: (self: VyTaxLoader, name: string) -> Component?,
	HasService: (self: VyTaxLoader, name: string) -> boolean,
	HasController: (self: VyTaxLoader, name: string) -> boolean,
	HasComponent: (self: VyTaxLoader, name: string) -> boolean,
	InjectService: (self: VyTaxLoader, name: string, instance: Service) -> (),
	InjectController: (self: VyTaxLoader, name: string, instance: Controller) -> (),
	Start: (self: VyTaxLoader) -> (),
	Destroy: (self: VyTaxLoader) -> (),
}

export type MiddlewareFn<T...> = (next: (...T...) -> (), ...T...) -> ()

export type PromiseState = "Resolved" | "Rejected" | "Pending"

export type Promise<T> = {
	State: PromiseState,
	Value: T?,
	Error: any?,
	Then: <U>(self: Promise<T>, callback: (T) -> U) -> Promise<U>,
	Catch: <U>(self: Promise<T>, callback: (any) -> U) -> Promise<U>,
	Finally: (self: Promise<T>, callback: () -> ()) -> Promise<T>,
	Await: (self: Promise<T>) -> (T?, any?),
}

export type Command = {
	Name: string,
	Description: string,
	Aliases: { string },
	Tag: string?,
	PermissionLevel: number,
	Cooldown: number,
	Callback: (player: Player, args: { string }) -> (),
}

return {}