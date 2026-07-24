class_name CustomerQueuePoint

var my_goal : Vector3;
var head_of_line : bool = false;
var front_customer : Customer;
var me : Customer;
var back_customer : Customer;

func create_customer_queue_point(myself : Customer, goal : Vector3, is_head : bool = false) -> CustomerQueuePoint:
    self.me = myself;
    self.my_goal = goal;
    self.head_of_line = is_head;
    return self;
    
func get_front() -> Customer:
    return self.front_customer;
    
func set_front(c : Customer) -> void:
    self.front_customer = c;
    
func get_back() -> Customer:
    return self.back_customer;

func set_back(c : Customer) -> void:
    self.back_customer = c;
