// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract IronOreMining is ERC20 {
    address public owner;
    AggregatorV3Interface internal priceFeed;

    enum ProductionPlanStatus {Active,Deactive,Completed}
    enum ProductionPhase {Drilling,Crushing,Refining,Transportation,Shipment}
    enum ApprovalStatus {Pending,Approved,Rejected}

    event TokensClaimed (address transferData,uint availableToken,uint claimAmount);

    struct ProductionPlan {
        uint maxSupply;
        uint totalSupply;
        uint startDate;
        uint endDate;
        ProductionPlanStatus status;
        mapping(ProductionPhase => ProductionPhaseDetails) phaseDetails;
        mapping(address => bool) approvers;
    }

    struct ProductionPhaseDetails {
        address vendor;
        mapping(address => ApprovalStatus) approvals;
        bool completed;
    }

    mapping(uint => ProductionPlan) public productionPlans;
    mapping(address => mapping(uint => uint)) public userTokenBalances;

    constructor() ERC20("Iron Ore Token","IORE") 
    {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner,"Only owner can perform this");
        _;
    }

    modifier onlyApprover(uint _planId,ProductionPhase _phase) 
    {
        require(productionPlans[_planId].approvers[msg.sender],"Only approver can perform this action");
        require(productionPlans[_planId].phaseDetails[_phase].approvals[msg.sender] == ApprovalStatus.Pending,"Already approved or reject");
        _;
    }

    function createProductionPlan(uint _planId,uint _maxSupply,uint _startDate,uint _endDate) external onlyOwner 
    {
        require(_planId > 0 && _maxSupply > 0 && _startDate > 0 && _endDate > _startDate,"Invalid input values");
        productionPlans[_planId].maxSupply = _maxSupply;
        productionPlans[_planId].startDate = _startDate;
        productionPlans[_planId].endDate = _endDate;
        productionPlans[_planId].status = ProductionPlanStatus.Active;
        _mint(owner,_maxSupply);
    }

    function addApprover(uint _planId,address _approver) external onlyOwner 
    {
        productionPlans[_planId].approvers[_approver] = true;
    }

    function removeApprover(uint _planId,address _approver) external onlyOwner 
    {
        productionPlans[_planId].approvers[_approver] = false;
    }

    function updateProductionPlan(uint _planId,uint _maxSupply,uint _startDate,uint _endDate) external onlyOwner 
    {
        require(_planId > 0 && _maxSupply > 0 && _startDate > 0 && _endDate > _startDate,"Invalid input values");
        productionPlans[_planId].maxSupply = _maxSupply;
        productionPlans[_planId].startDate = _startDate;
        productionPlans[_planId].endDate = _endDate;
    }

    function updateApproverAddress(uint _planId, ProductionPhase _phase, uint _index, address _newApprover) external onlyOwner 
    {
        require(productionPlans[_planId].phaseDetails[_phase].approvals[msg.sender] == ApprovalStatus.Pending, "Already approved or reject");
        require(_index >= 0 && _index < 3, "Invalid index");
        productionPlans[_planId].phaseDetails[_phase].approvals[_newApprover] = ApprovalStatus.Pending;
        productionPlans[_planId].phaseDetails[_phase].approvals[msg.sender] = ApprovalStatus.Approved;
    }

    function activateProductionPlan(uint _planId) external onlyOwner 
    {
        require(productionPlans[_planId].status == ProductionPlanStatus.Deactive,"plan is already active");
        productionPlans[_planId].status = ProductionPlanStatus.Active;
    }

    function deactivateProductionPlan(uint _planId) external onlyOwner 
    {
        require(productionPlans[_planId].status == ProductionPlanStatus.Active,"plan is already deactive");
        productionPlans[_planId].status = ProductionPlanStatus.Deactive;
    }

    function terminateProductionPlan(uint _planId) external onlyOwner 
    {
        require(productionPlans[_planId].status == ProductionPlanStatus.Active || 
        productionPlans[_planId].status == ProductionPlanStatus.Deactive,"plan is already completed");
        productionPlans[_planId].status = ProductionPlanStatus.Completed;
        _burn(owner,productionPlans[_planId].maxSupply);
    }

    function performDrilling(uint _planId,address _vendor,uint _amount) external onlyApprover(_planId,ProductionPhase.Drilling)
    {
        require(_vendor != address(0),"invalid vendor address");
        require(_amount > 0 && _amount <= balanceOf(owner),"invalid amount or insufficient balance");
        ProductionPhaseDetails storage details = productionPlans[_planId].phaseDetails[ProductionPhase.Drilling];
        details.vendor = _vendor;
        details.approvals[msg.sender] = ApprovalStatus.Approved;
        details.completed = true;
        _transfer(owner,_vendor,_amount);
    }

    function performCrushing(uint _planId,address _vendor,uint _amount) external onlyApprover(_planId,ProductionPhase.Crushing)
    {
        require(_vendor != address(0),"invalid vendor address");
        require(_amount > 0 && _amount <= balanceOf(owner),"invalid amount or insufficient balance");
        ProductionPhaseDetails storage details = productionPlans[_planId].phaseDetails[ProductionPhase.Crushing];
        details.vendor = _vendor;
        details.approvals[msg.sender] = ApprovalStatus.Approved;
        details.completed = true;
        _transfer(owner,_vendor,_amount);
    }

    function performRefining(uint _planId,address _vendor,uint _amount) external onlyApprover(_planId,ProductionPhase.Refining)
    {
        require(_vendor != address(0),"invalid vendor address");
        require(_amount > 0 && _amount <= balanceOf(owner),"invalid amount or insufficient balance");
        ProductionPhaseDetails storage details = productionPlans[_planId].phaseDetails[ProductionPhase.Refining];
        details.vendor = _vendor;
        details.approvals[msg.sender] = ApprovalStatus.Approved;
        details.completed = true;
        _transfer(owner,_vendor,_amount);
    }

    function performTransportation(uint _planId,address _vendor,uint _amount) external onlyApprover(_planId,ProductionPhase.Transportation)
    {
        require(_vendor != address(0),"invalid vendor address");
        require(_amount > 0 && _amount <= balanceOf(owner),"invalid amount or insufficient balance");
        ProductionPhaseDetails storage details = productionPlans[_planId].phaseDetails[ProductionPhase.Transportation];
        details.vendor = _vendor;
        details.approvals[msg.sender] = ApprovalStatus.Approved;
        details.completed = true;
        _transfer(owner,_vendor,_amount);
    }

    function performShipment(uint _planId,address _vendor,uint _amount) external onlyApprover(_planId,ProductionPhase.Shipment)
    {
        require(_vendor != address(0),"invalid vendor address");
        require(_amount > 0 && _amount <= balanceOf(owner),"invalid amount or insufficient balance");
        ProductionPhaseDetails storage details = productionPlans[_planId].phaseDetails[ProductionPhase.Shipment];
        details.vendor = _vendor;
        details.approvals[msg.sender] = ApprovalStatus.Approved;
        details.completed = true;
        _transfer(owner,_vendor,_amount);
    }    

    function claimToken() external view returns (uint) {
        uint availableToken = balanceOf(msg.sender);
        require(availableToken > 0,"no tokens available to claim");
        uint price = getETHUSDPrice();
        // uint claimAmount = availableToken.mul(1 ether).div(1000).mul(price).div(1 ether);
        uint256 USD = (availableToken*price)/1000;
        require(USD > 0,"claim amount must be greater than 0");
        // _burn(msg.sender,availableToken);
        // emit TokensClaimed(msg.sender,availableToken,USD);
        return USD;
    }

    function getETHUSDPrice() public view returns (uint) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint(price);
    }
}