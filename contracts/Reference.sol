pragma solidity >=0.4.21 <0.6.0;

contract Reference {
    
    // Reference Request Info 
    address recruiter;              // Recruiter Address 
    uint MIN_REWARD = 1;            // Minimum Price Of Reward(per Person)
    uint MAX_REWARD = 100;          // Maximum Price OF Reward(per Person)
    uint minReward;                 // Recruiter can choose amount of reward
    uint maxReward;
    uint public creationTime = now; // Created Time
    uint deadline;                  // Response Deadline 
    uint reward; 
    enum RequestStatus { 
        Created,                    // 요청 생성
        Reseaching,                 // 응답 진행중
        Done,                       // 응답 완료
        Rewarding,                  // 추가 보상 완료
        Completed                   // 
    }
    RequestStatus status = RequestStatus.Created;
    
    // Respondents Info 
    enum RespondentStatus{
        Wait,
        Answered,
        Rewarded
    }
    struct Respondent {
        RespondentStatus status;
        uint reward; 
        bool exists; // set to true 
    }
    
    mapping (address => Respondent) respondents;

    constructor(
        address[] memory _respondentAddress, 
        uint _minReward, 
        uint _maxReward, 
        uint _deadline
    ) payable public {
        require(_minReward >= MIN_REWARD, "minreward");
        require(_maxReward <= MAX_REWARD, "maxreward");
        require((_respondentAddress.length * _minReward) <= (msg.value/(1 ether)), "you should pay {1 * Num of Respondents} ether");
        
        recruiter = msg.sender;
        minReward = _minReward;
        maxReward = _maxReward;
        reward = msg.value;
        for(uint i=0; i<_respondentAddress.length;i++){
            require(!respondents[_respondentAddress[i]].exists, "Already Registered.");
            respondents[_respondentAddress[i]] = Respondent(RespondentStatus.Wait, 0, true);
        }
        deadline = _deadline;
        status = RequestStatus.Reseaching;
    }

    //  function getStatus() external view returns(uint _status, uint _deadline){
    //     _status = uint(status);
    //     _deadline = deadline;
    //     // return(_status, deadline);
    // }
    
    /**
     * 진행 상태
     */
    function getRequestState() external view returns(RequestStatus _status){
        _status = status;
    }
    
    // function getResponseStatus(address _respondent) external view returns(RespondentStatus _status){
    //     // require(respondents[_respondent], "unknown respondent.");
    //     _status = respondents[_respondent].status;
    // }
    

    modifier onlyRecruiter(){
        require(msg.sender == recruiter);
        _;
    }
    
    function sendReward(address payable _respondent) onlyRecruiter external {
        require(respondents[_respondent].exists, "Unvalid Address");
        require(respondents[_respondent].status == RespondentStatus.Answered, "Not Answered Address");

        uint cost = maxReward - minReward;
        respondents[_respondent].status = RespondentStatus.Rewarded;
        _respondent.transfer(cost * 1 ether);
    }
    
    function expire() onlyRecruiter external{
        // require(status==RequestStatus.Created);
        selfdestruct(msg.sender);
    }
    
        
    modifier onlyRespondents(){
        Respondent storage _respondent = respondents[msg.sender];
        require(_respondent.exists, "Unvalid Access");
        _; 
    }
    
    function answer() onlyRespondents external{
        require(status == RequestStatus.Reseaching, "Request is not valid"); 
        require(respondents[msg.sender].status == RespondentStatus.Wait, "You already answered.");
        
        respondents[msg.sender].status = RespondentStatus.Answered;
        msg.sender.transfer(MIN_REWARD * 1 ether);
    }
    
    // function getReward() onlyRespondents external{
    //     require(status == RequestStatus.Rewarding, "Unvalid Request");
    //     require(respondents[msg.sender].reward > 0, "There is no reward");
        
    //     msg.sender.transfer(reward * 1 ether);
    // }
    
}
