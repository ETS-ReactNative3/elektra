import { saveAs } from 'file-saver';
import * as constants from "../constants"
import { ajaxHelper, backendAjaxClient } from "./ajax_helper"
import "../lib/modal"
import {loadMetaData} from "./meta_data.coffee"
import {loadInfo} from "./info.coffee"
import {showConfirmDialog} from "./dialogs.coffee"
#################### CLUSTERS #########################
# ---- list ----
requestClusters = () ->
  type: constants.REQUEST_CLUSTERS

requestClustersFailure = (error) ->
  type: constants.REQUEST_CLUSTERS_FAILURE
  error: error

receiveClusters = (json, total) ->
  # cache clusters in elektra
  backendAjaxClient.post("/cache/objects",{contentType: "application/json", dataType: "json", data: {objects: json, type: "kubernikus_cluster"}})

  {type: constants.RECEIVE_CLUSTERS
  clusters: json
  total: total}


loadClusters = () ->
  (dispatch, getState) ->
    currentState    = getState()
    clusters        = currentState.clusters
    isFetching      = clusters.isFetching


    return if isFetching # don't fetch if we're already fetching
    dispatch(requestClusters())

    ajaxHelper.get '/api/v1/clusters',
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(receiveClusters(data))
      error: ( jqXHR, textStatus, errorThrown) ->
        errorMessage =  if typeof jqXHR.responseJSON == 'object'
                          jqXHR.responseJSON.message
                        else
                          if jqXHR.responseText.length > 0
                            jqXHR.responseText
                          else
                            "The backend is currently slow to respond. Please try again later. We are on it."


        dispatch(requestClustersFailure(errorMessage))



fetchClusters = () ->
  (dispatch) ->
    dispatch(loadClusters())


# ---- CLUSTER ----
requestCluster = (clusterName) ->
  type: constants.REQUEST_CLUSTER
  clusterName: clusterName

requestClusterFailure = (error) ->
  type: constants.REQUEST_CLUSTER_FAILURE
  error: error

receiveCluster = (cluster) ->
  type: constants.RECEIVE_CLUSTER
  cluster: cluster

startPollingCluster = (clusterName) ->
  type: constants.START_POLLING_CLUSTER
  clusterName: clusterName

stopPollingCluster = (clusterName) ->
  type: constants.STOP_POLLING_CLUSTER
  clusterName: clusterName


loadCluster = (clusterName) ->
  (dispatch, getState) ->
    # currentState    = getState()
    # cluster         = currentState.clusters
    # isFetching      = clusters.isFetching


    # return if isFetching # don't fetch if we're already fetching
    dispatch(requestCluster(clusterName))

    ajaxHelper.get "/api/v1/clusters/#{clusterName}",
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(receiveCluster(data))
      error: ( jqXHR, textStatus, errorThrown) ->
        unless jqXHR?
          dispatch(loadClusters()) # if no valid object is returned, just reload the whole list
        else
        switch jqXHR.status
          when 404 then dispatch(loadClusters()) # if requested cluster not found reload the whole list to see what we have (the cluster was probably deleted)
          else
            errorMessage =  if typeof jqXHR.responseJSON == 'object'
                              jqXHR.responseJSON.message
                            else jqXHR.responseText
            dispatch(requestClusterFailure(errorMessage))


# -------------- CLUSTER EVENTS ---------------

requestClusterEvents = (clusterName) ->
  type: constants.REQUEST_CLUSTER_EVENTS
  clusterName: clusterName

requestClusterEventsFailure = (error) ->
  type: constants.REQUEST_CLUSTER_EVENTS_FAILURE
  error: error

receiveClusterEvents = (clusterName, events) ->
  type: constants.RECEIVE_CLUSTER_EVENTS
  clusterName: clusterName
  events: events

loadClusterEvents = (clusterName) ->
  (dispatch, getState) ->

    # return if isFetching # don't fetch if we're already fetching
    dispatch(requestClusterEvents(clusterName))

    ajaxHelper.get "/api/v1/clusters/#{clusterName}/events",
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(receiveClusterEvents(clusterName, data))
      error: ( jqXHR, textStatus, errorThrown) ->
        errorMessage =  if typeof jqXHR.responseJSON == 'object'
                          jqXHR.responseJSON.message
                        else jqXHR.responseText
        dispatch(requestClusterEventsFailure(errorMessage))


# -------------- CREATE ---------------

newClusterModal= () ->
  type: ReactModal.SHOW_MODAL,
  modalType: 'NEW_CLUSTER'

openNewClusterDialog = () ->
  (dispatch) ->
    dispatch(loadMetaData())
    dispatch(loadInfo(workflow: 'new'))
    dispatch(clusterFormForCreate())
    dispatch(newClusterModal())

toggleAdvancedOptions = () ->
  type: constants.FORM_TOGGLE_ADVANCED_OPTIONS


# -------------- EDIT ---------------

editClusterModal= () ->
  type: ReactModal.SHOW_MODAL,
  modalType: 'EDIT_CLUSTER'

openEditClusterDialog = (cluster) ->
  (dispatch) ->
    dispatch(loadMetaData())
    dispatch(loadInfo({}))
    dispatch(clusterFormForUpdate(cluster))
    dispatch(editClusterModal())


# -------------- DELETE ---------------

requestDeleteCluster = (clusterName) ->
  (dispatch) ->
    dispatch(showConfirmDialog({
      title: 'Delete Cluster'
      message: "Do you really want to delete cluster #{clusterName}?",
      confirmCallback: (() -> dispatch(deleteCluster(clusterName)))
    }))


deleteCluster = (clusterName) ->
  (dispatch) ->
    dispatch(deleteClusterConfirmed(clusterName))

    ajaxHelper.delete "/api/v1/clusters/#{clusterName}",
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(fetchClusters())
      error: ( jqXHR, textStatus, errorThrown) ->
        errorMessage =  if typeof jqXHR.responseJSON == 'object'
                          jqXHR.responseJSON.message
                        else jqXHR.responseText
        dispatch(deleteClusterFailure(clusterName, errorMessage))


deleteClusterConfirmed = () ->
  type: constants.DELETE_CLUSTER

deleteClusterFailure = (clusterName, error) ->
  type: constants.DELETE_CLUSTER_FAILURE
  error: "Couldn't delete cluster #{clusterName}: #{error}"


# -------------- CREDENTIALS ---------------

getCredentials = (clusterName) ->
  (dispatch) ->
    dispatch(requestCredentials(clusterName))

    ajaxHelper.get "/api/v1/clusters/#{clusterName}/credentials",
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(receiveCredentials(clusterName, data))
      error: ( jqXHR, textStatus, errorThrown) ->
        dispatch(requestCredentialsFailure(clusterName, jqXHR.responseText))


requestCredentials = () ->
  type: constants.REQUEST_CREDENTIALS

requestCredentialsFailure = (clusterName, error) ->
  type: constants.REQUEST_CREDENTIALS_FAILURE
  flashError: "We couldn't retrieve the credentials for cluster #{clusterName} at this time. This might be because the cluster is not ready yet or is in an error state. Please try again."

receiveCredentials = (clusterName, credentials) ->
  (dispatch) ->
    blob = new Blob([credentials.kubeconfig], {type: "application/x-yaml;charset=utf-8"})
    saveAs(blob, "#{clusterName}-config")



# -------------- SETUP ---------------

getSetupInfo = (clusterName, kubernikusBaseUrl) ->
  (dispatch) ->
    dispatch(requestSetupInfo(clusterName))

    ajaxHelper.get "/api/v1/clusters/#{clusterName}/info",
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(receiveSetupInfo(clusterName,kubernikusBaseUrl, data))
      error: ( jqXHR, textStatus, errorThrown) ->
        dispatch(requestSetupInfoFailure(clusterName, jqXHR.responseText))


requestSetupInfo = () ->
  type: constants.REQUEST_SETUP_INFO

requestSetupInfoFailure = (clusterName, error) ->
  type: constants.REQUEST_SETUP_INFO_FAILURE
  flashError: "We couldn't retrieve the setup information for cluster #{clusterName} at this time. This might be because the cluster is not ready yet or is in an error state. Please try again."

receiveSetupInfo = (clusterName, kubernikusBaseUrl, setupInfo) ->
  (dispatch) ->
    dispatch(dataForSetupInfo(setupInfo, kubernikusBaseUrl))
    dispatch(setupInfoModal())


setupInfoModal= () ->
  type: ReactModal.SHOW_MODAL,
  modalType: 'SETUP_INFO'

dataForSetupInfo = (data, kubernikusBaseUrl) ->
  type: constants.SETUP_INFO_DATA
  setupData: data
  kubernikusBaseUrl: kubernikusBaseUrl



################# CLUSTER FORM ######################

clusterFormForCreate = () ->
  type: constants.PREPARE_CLUSTER_FORM
  method: 'post'
  action: "/api/v1/clusters"

resetClusterForm = () ->
  type: constants.RESET_CLUSTER_FORM

closeClusterForm = () ->
  (dispatch) ->
    dispatch(resetClusterForm())

clusterFormForUpdate = (cluster) ->
  type: constants.PREPARE_CLUSTER_FORM
  data: cluster
  method: 'put'
  action: "/api/v1/clusters/#{cluster.name}"

clusterFormFailure = (errors) ->
  type: constants.CLUSTER_FORM_FAILURE
  errors: errors

updateClusterForm = (name,value) ->
  type: constants.UPDATE_CLUSTER_FORM
  name: name
  value: value

updateAdvancedOptions = (name, value) ->
  (dispatch) ->
    switch name
      when 'routerID'  then dispatch(setDefaultsForRouter(value))
      when 'networkID' then dispatch(setDefaultsForNetwork(value))
      else dispatch(updateAdvancedValue(name, value))

changeVersion = (value) ->
  type: constants.FORM_CHANGE_VERSION
  value: value

setDefaultsForRouter = (value) ->
  (dispatch, getState) ->
    metaData = getState().metaData
    # going down the nested array rabbit hole
    selectedRouterIndex = ReactHelpers.findIndexInArray(metaData.routers,value, 'id')
    selectedRouter      = metaData.routers[selectedRouterIndex]
    defaultNetwork      = selectedRouter.networks[0]
    defaultSubnet       = defaultNetwork.subnets[0]

    dispatch(updateAdvancedValue('routerID',    value))
    dispatch(updateAdvancedValue('networkID',   defaultNetwork.id))
    dispatch(updateAdvancedValue('lbSubnetID',  defaultSubnet.id))



setDefaultsForNetwork = (value) ->
  (dispatch, getState) ->
    metaData = getState().metaData
    # going down the nested array rabbit hole
    selectedRouterIndex     = ReactHelpers.findIndexInArray(metaData.routers,getState().clusterForm.data.spec.openstack.routerID, 'id')
    selectedRouter          = metaData.routers[selectedRouterIndex]
    selectedNetworkIndex    = ReactHelpers.findIndexInArray(selectedRouter.networks,value, 'id')
    selectedNetwork         = selectedRouter.networks[selectedNetworkIndex]
    defaultSubnet           = selectedNetwork.subnets[0]

    dispatch(updateAdvancedValue('networkID', value))
    dispatch(updateAdvancedValue('lbSubnetID', defaultSubnet.id))



updateAdvancedValue = (name, value) ->
  type: constants.FORM_UPDATE_ADVANCED_VALUE
  name: name
  value: value

updateSSHKey = (value) ->
  type: constants.FORM_UPDATE_SSH_KEY
  value: value

updateKeyPair = (value) ->
  (dispatch) ->
    dispatch(setKeyPair(value))
    keyValue = if value == 'other' then '' else value
    dispatch(updateSSHKey(keyValue))

setKeyPair = (value) ->
  type: constants.FORM_UPDATE_KEY_PAIR
  value: value

updateNodePoolForm = (index, name, value) ->
  type: constants.UPDATE_NODE_POOL_FORM
  index: index
  name: name
  value: value
  

addNodePool = (defaultAZ) ->
  type: constants.ADD_NODE_POOL
  defaultAZ: defaultAZ

deleteNodePool = (index) ->
  type: constants.DELETE_NODE_POOL
  index: index


submitClusterForm = (successCallback=null) ->
  (dispatch, getState) ->
    clusterForm = getState().clusterForm
    if clusterForm.isValid
      dispatch(type: constants.SUBMIT_CLUSTER_FORM)
      ajaxHelper[clusterForm.method] clusterForm.action,
        contentType: 'application/json'
        data: clusterForm.data

        success: (data, textStatus, jqXHR) ->
          dispatch(resetClusterForm())
          dispatch(receiveCluster(data))
          successCallback() if successCallback
        error: ( jqXHR, textStatus, errorThrown) ->
          errorMessage =  if typeof jqXHR.responseJSON == 'object'
                            jqXHR.responseJSON.message
                          else jqXHR.responseText

          dispatch(clusterFormFailure("Please Note": [errorMessage]))



# export
export {
  fetchClusters,      
  requestDeleteCluster,      
  openNewClusterDialog,      
  openEditClusterDialog,      
  toggleAdvancedOptions,      
  updateAdvancedOptions,      
  changeVersion,      
  updateSSHKey,      
  updateKeyPair,      
  loadCluster,      
  loadClusterEvents,      
  getCredentials,      
  getSetupInfo,      
  clusterFormForCreate,      
  clusterFormForUpdate,      
  submitClusterForm,      
  closeClusterForm,      
  updateClusterForm,      
  updateNodePoolForm,      
  addNodePool,      
  deleteNodePool,      
  startPollingCluster,      
  stopPollingCluster      
}