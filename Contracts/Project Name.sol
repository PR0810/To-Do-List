// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TodoList {
    struct Task {
        uint256 id;
        string content;
        string description;
        string priority;
        bool completed;
        uint256 createdAt;
        uint256 completedAt;
        address owner;
        bool exists;
    }
    
    mapping(address => mapping(uint256 => Task)) private userTasks;
    mapping(address => uint256) public userTaskCounts;
    mapping(address => uint256[]) private userTaskIds;
    
    uint256 private globalTaskCounter;
    
    event TaskCreated(
        address indexed user,
        uint256 indexed taskId,
        string content,
        string priority,
        uint256 timestamp
    );
    
    event TaskCompleted(
        address indexed user,
        uint256 indexed taskId,
        uint256 timestamp
    );
    
    event TaskDeleted(
        address indexed user,
        uint256 indexed taskId,
        uint256 timestamp
    );
    
    event TaskUpdated(
        address indexed user,
        uint256 indexed taskId,
        string newContent,
        string newDescription,
        string newPriority,
        uint256 timestamp
    );

    modifier taskExists(uint256 _taskId) {
        require(userTasks[msg.sender][_taskId].exists, "Task does not exist");
        _;
    }

    modifier validPriority(string memory _priority) {
        require(
            keccak256(bytes(_priority)) == keccak256(bytes("low")) ||
            keccak256(bytes(_priority)) == keccak256(bytes("medium")) ||
            keccak256(bytes(_priority)) == keccak256(bytes("high")),
            "Priority must be: low, medium, or high"
        );
        _;
    }

    function createTask(
        string memory _content,
        string memory _description,
        string memory _priority
    ) public validPriority(_priority) {
        require(bytes(_content).length > 0, "Task content cannot be empty");
        require(bytes(_content).length <= 200, "Task content too long");
        require(bytes(_description).length <= 500, "Description too long");
        
        uint256 taskId = globalTaskCounter;
        globalTaskCounter++;
        
        userTasks[msg.sender][taskId] = Task({
            id: taskId,
            content: _content,
            description: _description,
            priority: _priority,
            completed: false,
            createdAt: block.timestamp,
            completedAt: 0,
            owner: msg.sender,
            exists: true
        });
        
        userTaskIds[msg.sender].push(taskId);
        userTaskCounts[msg.sender]++;
        
        emit TaskCreated(msg.sender, taskId, _content, _priority, block.timestamp);
    }
    
    function completeTask(uint256 _taskId) public taskExists(_taskId) {
        require(!userTasks[msg.sender][_taskId].completed, "Task already completed");
        
        userTasks[msg.sender][_taskId].completed = true;
        userTasks[msg.sender][_taskId].completedAt = block.timestamp;
        
        emit TaskCompleted(msg.sender, _taskId, block.timestamp);
    }
    
    function uncompleteTask(uint256 _taskId) public taskExists(_taskId) {
        require(userTasks[msg.sender][_taskId].completed, "Task is not completed");
        
        userTasks[msg.sender][_taskId].completed = false;
        userTasks[msg.sender][_taskId].completedAt = 0;
    }
    
    function deleteTask(uint256 _taskId) public taskExists(_taskId) {
        // Remove from userTaskIds array
        uint256[] storage taskIds = userTaskIds[msg.sender];
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (taskIds[i] == _taskId) {
                taskIds[i] = taskIds[taskIds.length - 1];
                taskIds.pop();
                break;
            }
        }
        
        delete userTasks[msg.sender][_taskId];
        userTaskCounts[msg.sender]--;
        
        emit TaskDeleted(msg.sender, _taskId, block.timestamp);
    }
    
    function updateTask(
        uint256 _taskId,
        string memory _newContent,
        string memory _newDescription,
        string memory _newPriority
    ) public taskExists(_taskId) validPriority(_newPriority) {
        require(bytes(_newContent).length > 0, "Task content cannot be empty");
        require(bytes(_newContent).length <= 200, "Task content too long");
        require(bytes(_newDescription).length <= 500, "Description too long");
        
        Task storage task = userTasks[msg.sender][_taskId];
        task.content = _newContent;
        task.description = _newDescription;
        task.priority = _newPriority;
        
        emit TaskUpdated(msg.sender, _taskId, _newContent, _newDescription, _newPriority, block.timestamp);
    }
    
    function getTask(uint256 _taskId) public view returns (
        uint256 id,
        string memory content,
        string memory description,
        string memory priority,
        bool completed,
        uint256 createdAt,
        uint256 completedAt,
        address owner
    ) {
        require(userTasks[msg.sender][_taskId].exists, "Task does not exist");
        
        Task memory task = userTasks[msg.sender][_taskId];
        return (
            task.id,
            task.content,
            task.description,
            task.priority,
            task.completed,
            task.createdAt,
            task.completedAt,
            task.owner
        );
    }
    
    function getAllTasks() public view returns (Task[] memory) {
        uint256[] memory taskIds = userTaskIds[msg.sender];
        Task[] memory tasks = new Task[](taskIds.length);
        
        for (uint256 i = 0; i < taskIds.length; i++) {
            tasks[i] = userTasks[msg.sender][taskIds[i]];
        }
        
        return tasks;
    }
    
    function getTasksByStatus(bool _completed) public view returns (Task[] memory) {
        uint256[] memory taskIds = userTaskIds[msg.sender];
        uint256 count = 0;
        
        // Count matching tasks
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (userTasks[msg.sender][taskIds[i]].completed == _completed) {
                count++;
            }
        }
        
        // Create result array
        Task[] memory tasks = new Task[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (userTasks[msg.sender][taskIds[i]].completed == _completed) {
                tasks[index] = userTasks[msg.sender][taskIds[i]];
                index++;
            }
        }
        
        return tasks;
    }
    
    function getTasksByPriority(string memory _priority) public view validPriority(_priority) returns (Task[] memory) {
        uint256[] memory taskIds = userTaskIds[msg.sender];
        uint256 count = 0;
        
        // Count matching tasks
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (keccak256(bytes(userTasks[msg.sender][taskIds[i]].priority)) == keccak256(bytes(_priority))) {
                count++;
            }
        }
        
        // Create result array
        Task[] memory tasks = new Task[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (keccak256(bytes(userTasks[msg.sender][taskIds[i]].priority)) == keccak256(bytes(_priority))) {
                tasks[index] = userTasks[msg.sender][taskIds[i]];
                index++;
            }
        }
        
        return tasks;
    }
    
    function getTaskCount() public view returns (uint256) {
        return userTaskIds[msg.sender].length;
    }
    
    function getCompletedTasksCount() public view returns (uint256) {
        uint256[] memory taskIds = userTaskIds[msg.sender];
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (userTasks[msg.sender][taskIds[i]].completed) {
                completedCount++;
            }
        }
        
        return completedCount;
    }
    
    function getPendingTasksCount() public view returns (uint256) {
        return getTaskCount() - getCompletedTasksCount();
    }
    
    function getGlobalTaskCount() public view returns (uint256) {
        return globalTaskCounter;
    }
}
