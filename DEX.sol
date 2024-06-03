// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    struct Order {
        address trader;
        bool buy;
        IERC20 token;
        uint256 amount;
        uint256 price;
    }

    uint256 public orderCount;
    mapping(uint256 => Order) public orders;

    event OrderPlaced(uint256 orderId, address trader, bool buy, address token, uint256 amount, uint256 price);
    event OrderFilled(uint256 orderId, address trader, uint256 amount);

    function placeOrder(bool buy, address token, uint256 amount, uint256 price) external {
        require(amount > 0 && price > 0, "Invalid order");

        orderCount++;
        orders[orderCount] = Order(msg.sender, buy, IERC20(token), amount, price);

        emit OrderPlaced(orderCount, msg.sender, buy, token, amount, price);
    }

    function fillOrder(uint256 orderId, uint256 amount) external payable {
        Order storage order = orders[orderId];
        require(order.amount >= amount, "Order amount too high");
        require(order.price * amount == msg.value, "Incorrect ETH amount");

        order.amount -= amount;
        if (order.buy) {
            require(order.token.transferFrom(msg.sender, order.trader, amount), "Transfer failed");
        } else {
            require(order.token.transferFrom(order.trader, msg.sender, amount), "Transfer failed");
            payable(order.trader).transfer(msg.value);
        }

        emit OrderFilled(orderId, msg.sender, amount);
    }

    function getOrder(uint256 orderId) external view returns (address trader, bool buy, address token, uint256 amount, uint256 price) {
        Order storage order = orders[orderId];
        return (order.trader, order.buy, address(order.token), order.amount, order.price);
    }
}
