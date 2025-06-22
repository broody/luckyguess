use starknet::ContractAddress;

#[starknet::interface]
pub trait IToken<TState> {
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn balanceOf(ref self: TState, owner: ContractAddress) -> u256;
}