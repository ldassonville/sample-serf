package cluster

import (
	"github.com/hashicorp/serf/serf"
	"github.com/sirupsen/logrus"
)



type SerfNode struct {

	cfg *SerfNodeConfig

	eventChan chan serf.Event
	stopChan  chan struct{}
	log       *logrus.Logger
	serf *serf.Serf
}

type SerfNodeConfig struct {
	Name 	string

	BindAddr string
	BindPort int

	AdvertiseAddr string
	AdvertisePort int

	Members []SerfMember

}

type SerfMember struct{
	Name 	string
	Status string
	Address string
}

func New(cfg *SerfNodeConfig) *SerfNode{

	node := &SerfNode{
		cfg: cfg,
		log:       logrus.New(),
		stopChan:  make(chan struct{}),
		eventChan: make(chan serf.Event, 100),
	}
	return node;
}



func (node *SerfNode) Setup() error {

	conf := serf.DefaultConfig()
	conf.Init()
	conf.EventCh = node.eventChan


	conf.Tags = map[string]string{
		"name": node.cfg.Name,
	}

	conf.MemberlistConfig.BindPort = node.cfg.BindPort
	conf.MemberlistConfig.BindAddr = node.cfg.BindAddr

	conf.MemberlistConfig.AdvertisePort = node.cfg.AdvertisePort
	conf.MemberlistConfig.AdvertiseAddr = node.cfg.AdvertiseAddr


	// Cluster creation
	cluster, err := serf.Create(conf)
	if err != nil {
		return err
	}

	var clusterAddresses []string

	// Add other cluster members
	for _, member := range node.cfg.Members {
		clusterAddresses = append(clusterAddresses, member.Address)
	}

	_, err = cluster.Join(clusterAddresses, true)
	if err != nil {
		logrus.Warning("Couldn't join cluster, starting own: %v", err)
	}

	node.serf = cluster
	return nil
}



// Give the serf member list
func (n *SerfNode) GetMembers() []SerfMember{

	var res []SerfMember;

	for _, m := range n.serf.Members(){
		res = append(res, SerfMember{ Name: m.Name, Status: m.Status.String() })
	}
	return res;
}


func (n *SerfNode) PrintClusterEvents() {
	go n.printClusterEvents()
}

// Log serf cluster events
func (n *SerfNode) printClusterEvents() {

	for {
		select {

		case event := <-n.eventChan:

			if serf.EventMemberJoin == event.EventType(){

				memberEvent := event.(serf.MemberEvent)
				n.log.Infof("Event receive events %s for members %s",  memberEvent.Type, memberEvent.Members)
			}

		case <-n.stopChan:
			n.log.Info("Stopping cluster event process")
			return
		}
	}
}


// Serf node leave the cluster
func (n *SerfNode) Leave(){
	n.serf.Leave()
}