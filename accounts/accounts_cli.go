package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/codegangsta/cli"
	"github.com/howeyc/gopass"
)

// Represents the user running the audit on the accounts that they have access to via permissons
type admin struct {
	host   string
	client *http.Client
	User   struct {
		Id    string `json:"userid"`
		Name  string `json:"username"`
		Token string `json:"-"`
	} `json:"administrator"`
	Accounts []*Account `json:"administeredAccounts"`
}

// Account details that we will audit
type Account struct {
	Id      string `json:"userid"`
	Profile struct {
		FullName string `json:"fullName"`
		Patient  struct {
			Bday string `json:"birthday"`
			Dday string `json:"diagnosisDate"`
		} `json:"patient"`
	} `json:"patientProfile"`
	Perms      interface{} `json:"permissons"`
	LastUpload string      `json:"lastupload"`
}

var (
	prodHost    = "https://api.tidepool.io"
	stagingHost = "https://staging-api.tidepool.io"
	develHost   = "https://devel-api.tidepool.io"
	localHost   = "http://localhost:8009"
)

func main() {

	app := cli.NewApp()

	app.Name = "Accounts-Managment"
	app.Usage = "Allows the bulk management of tidepool accounts"
	app.Version = "0.0.1"
	app.Author = "Jamie Bate"
	app.Email = "jamie@tidepool.org"

	app.Commands = []cli.Command{

		//e.g. audit --af ./accounts.txt
		{
			Name:      "audit",
			ShortName: "a",
			Usage:     `audit all accounts that you have permisson to access`,
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:  "e, env",
					Value: "local",
					Usage: "the environment your running against. Options are local, devel, staging and prod",
				},
				cli.StringFlag{
					Name:  "u, username",
					Usage: "your tidepool username that has access to the accounts e.g. admin@tidepool.org",
				},
				cli.StringFlag{
					Name:  "r, reportpath",
					Usage: "rerun the process on an existing report that you have given the path too e.g -r ./accountsAudit_2015-06-26 08:17:29.445414108 +1200 NZST.txt",
				},
			},
			Action: auditAccounts,
		},
	}

	app.Run(os.Args)

}

func (a *admin) findPublicInfo(acc *Account) error {

	urlPath := a.host + fmt.Sprintf("/metadata/%s/profile", acc.Id)

	req, _ := http.NewRequest("GET", urlPath, nil)
	req.Header.Add("x-tidepool-session-token", a.User.Token)

	res, err := a.client.Do(req)

	if err != nil {
		return errors.New("Could attempt to find profile: " + err.Error())
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)
		json.Unmarshal(data, &acc.Profile)
		return nil
	default:
		log.Printf("Failed finding public info [%d] for [%s]", res.StatusCode, acc.Id)
		return nil
	}
}

func (a *admin) findLastUploaded(acc *Account) error {

	urlPath := a.host + fmt.Sprintf("/query/upload/lastentry/%s", acc.Id)

	req, _ := http.NewRequest("GET", urlPath, nil)
	req.Header.Add("x-tidepool-session-token", a.User.Token)

	res, err := a.client.Do(req)

	if err != nil {
		return errors.New("Could attempt to find the last upload: " + err.Error())
	}

	switch res.StatusCode {
	case 200:
		data, err := ioutil.ReadAll(res.Body)

		if err != nil {
			log.Println("Error trying to read the last upload data", err.Error())
			return nil
		}

		json.Unmarshal(data, &acc.LastUpload)
		log.Println("Found last upload data ", string(data[:]))
		return nil
	default:
		log.Printf("Failed finding last upload info [%d] for [%s]", res.StatusCode, acc.Profile.FullName)
		return nil
	}
}

func (a *admin) login(un, pw string) error {

	urlPath := a.host + "/auth/login"

	req, _ := http.NewRequest("POST", urlPath, nil)
	req.SetBasicAuth(un, pw)

	res, err := a.client.Do(req)
	if err != nil {
		return errors.New(fmt.Sprint("Login request failed", err.Error()))
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)
		json.Unmarshal(data, &a.User)
		a.User.Token = res.Header.Get("x-tidepool-session-token")
		return nil
	default:
		return errors.New(fmt.Sprint("Login failed", res.StatusCode))
	}
}

func (a *admin) findAccounts() error {

	urlPath := a.host + fmt.Sprintf("/access/groups/%s", a.User.Id)

	req, _ := http.NewRequest("GET", urlPath, nil)
	req.Header.Add("x-tidepool-session-token", a.User.Token)

	res, err := a.client.Do(req)

	if err != nil {
		return errors.New("Could attempt to find administered accounts: " + err.Error())
	}

	switch res.StatusCode {
	case 200:
		data, _ := ioutil.ReadAll(res.Body)

		var raw map[string]interface{}

		json.Unmarshal(data, &raw)

		for key, value := range raw {
			a.Accounts = append(a.Accounts, &Account{Id: string(key), Perms: value})
		}
		return nil
	default:
		log.Println("Failed finding profiles", res.StatusCode)
		return nil
	}
}

func (a *admin) loadExistingReport(path string) error {
	log.Println("loading audit report ...")

	rf, err := os.Open(path)
	if err != nil {
		return err
	}

	jsonParser := json.NewDecoder(rf)
	if err = jsonParser.Decode(&a); err != nil {
		return err
	}
	rf.Close()
	return nil
}

func (a *admin) accountDetails() {
	var wg sync.WaitGroup

	for _, account := range a.Accounts {
		// Increment the WaitGroup counter.
		wg.Add(1)
		// Launch a goroutine to account data
		go func(account *Account) {
			// Decrement the counter when the goroutine completes.
			defer wg.Done()
			// Fetch the account data
			a.findPublicInfo(account)
		}(account)
	}
	// Wait for all fetches to complete.
	wg.Wait()
	return
}
func (a *admin) audit() {

	var wg sync.WaitGroup

	for _, account := range a.Accounts {
		// Increment the WaitGroup counter.
		wg.Add(1)
		// Launch a goroutine to account data
		go func(account *Account) {
			// Decrement the counter when the goroutine completes.
			defer wg.Done()
			a.findLastUploaded(account)
		}(account)
	}
	// Wait for all fetches to complete.
	wg.Wait()
	return
}

func setHost(targetEnv string) string {

	targetEnv = strings.ToLower(targetEnv)

	fmt.Println("Run audit against:", targetEnv)

	if targetEnv == "devel" {
		return develHost
	} else if targetEnv == "prod" {
		return prodHost
	} else if targetEnv == "staging" {
		return stagingHost
	}
	return localHost
}

// and audit will find all account linked
func auditAccounts(c *cli.Context) {

	if c.String("username") == "" {
		log.Fatal("Please specify the username with the --username or -u flag.")
	}

	adminUser := &admin{host: setHost(c.String("env")), client: &http.Client{}}

	fmt.Printf("Password: ")
	pass := gopass.GetPasswdMasked()

	err := adminUser.login(c.String("username"), string(pass[:]))
	if err != nil {
		log.Println(err.Error())
		return
	}

	if c.String("reportpath") == "" {

		//get accounts I can view
		log.Println("finding administered accounts ...")
		err = adminUser.findAccounts()
		if err != nil {
			log.Println(err.Error())
			return
		}
		log.Println("get users info ...")
		adminUser.accountDetails()

	} else {
		//find the accociated profiles
		log.Println("re-running audit on accounts ...")

		err = adminUser.loadExistingReport(c.String("reportpath"))
		if err != nil {
			log.Println(err.Error())
			return
		}
	}

	log.Println("running audit on accounts ...")
	start := time.Now()
	adminUser.audit()
	log.Printf("audit took [%f]secs", time.Now().Sub(start).Seconds())

	log.Println("building audit report ...")
	jsonRpt, _ := json.MarshalIndent(&adminUser, "", "  ")

	reportPath := fmt.Sprintf("./audit_%s_accounts_%s_%s.txt", adminUser.User.Name, c.String("env"), time.Now().UTC().Format(time.RFC3339))

	f, _ := os.Create(reportPath)
	defer f.Close()
	f.Write(jsonRpt)
	log.Println("done! here is the report " + reportPath)
	//see when they last uploaded

	return
}
