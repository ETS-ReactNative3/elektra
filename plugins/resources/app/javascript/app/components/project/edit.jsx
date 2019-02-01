import { Modal, Button } from 'react-bootstrap';

import { byUIString, t } from '../../utils';
import ProjectResource from '../../components/project/resource';
import { Unit } from '../../unit';

export default class ProjectEditModal extends React.Component {
  state = {
    //This will be set to false by this.close().
    show: true,
    //The `inputs` object contains the editing state for each input field. The
    //key is the resource name.
    inputs: null,
    //The `isFollowing` field is a boolean that indicates whether resources
    //with scaling relation currently follow their leader, or `null` if
    //there are no resources with scaling relation.
    isFollowing: null,
    //The `canFollow` field tracks which resources have usable scaling relations.
  }

  //NOTE: These fields hold active timers (as started by setTimeout()). This is
  //not part of `state` because starting or stopping timers does not cause a
  //redraw, and `render()` does not need to mess with the timers.
  asyncParseInputsTimer = null;

  componentWillReceiveProps(nextProps) {
    this.initializeValuesIfNecessary(nextProps);
  }

  componentDidMount() {
    this.initializeValuesIfNecessary(this.props);
  }

  initializeValuesIfNecessary = (props) => {
    //do this only once
    if (this.state.inputs) {
      return;
    }
    //do this only when we have project data
    const { resources } = props.category || {};
    if (!resources) {
      return;
    }

    //initialize the state of the input form
    const inputs = {};
    const hasResource = {};
    const canFollow = {};
    let isFollowing = undefined;
    for (let res of resources) {
      const unit = new Unit(res.unit);
      inputs[res.name] = {
        value: res.quota,
        text: unit.format(res.quota, { ascii: true }),
      };
      hasResource[res.name] = true;
    }
    for (let res of resources) {
      //can only use scaling relations between resources in the same service+category
      if (res.scales_with && res.scales_with.service_type == props.category.serviceType) {
        if (hasResource[res.scales_with.resource_name]) {
          canFollow[res.name] = true;
          isFollowing = true;
        }
      }
    }

    this.setState({...this.state, inputs, isFollowing, canFollow });
  }

  //This gets called by the input fields' onChange event.
  handleInput = (resourceName, inputText) => {
    //update inputTexts immediately
    const newState = { ...this.state };
    newState.inputs = { ...this.state.inputs };
    const oldInputState = this.state.inputs[resourceName];
    newState.inputs[resourceName] = { ...oldInputState, text: inputText };
    this.setState(newState);

    //do not attempt to update inputs[].value etc. immediately; wait until the
    //user has stopped typing
    if (this.asyncParseInputsTimer) {
      window.clearTimeout(this.asyncParseInputsTimer);
    }
    this.asyncParseInputsTimer = setTimeout(this.triggerParseInputs, 2000);
  };

  //Parses the user's quota inputs. This gets called asynchronously by
  //handleInput() after the user has stopped typing, but is also triggered
  //eagerly by events on the input field (e.g. Tab/Enter keys or mouse-out)
  //following a "do what I mean" strategy.
  triggerParseInputs = (additionalStateChanges={}) => {
    const newState = { ...this.state, ...additionalStateChanges, inputs: {} };
    for (let res of this.props.category.resources) {
      const unit = new Unit(res.unit);
      const oldInput = this.state.inputs[res.name];
      const input = { text: oldInput.text };
      newState.inputs[res.name] = input;

      //if the user has not modified the input text, always use the original
      //value (this may be different from `unit.parse(inputText)` if the
      //formatting removed some decimal places)
      const originalText = unit.format(res.quota, { ascii: true });
      if (originalText == input.text) {
        input.value = res.quota;
        continue;
      }

      //attempt to parse the user's input
      const parsedValue = unit.parse(input.text);
      if (parsedValue.error) {
        //parse error -> continue to show the previous value on the bar
        input.value = oldInput.value;
        input.error = parsedValue.error;
      } else {
        input.value = parsedValue;
        if (parsedValue < res.usage) {
          input.error = 'overspent';
        }
      }
    }

    //follower resources have their values computed automatically
    if (newState.isFollowing) {
      for (let res of this.props.category.resources) {
        if (!this.state.canFollow[res.name]) {
          continue;
        }
        const baseResName = res.scales_with.resource_name;
        const baseRes = this.props.category.resources.find(res => res.name == baseResName);
        const baseInput = newState.inputs[baseResName];

        //do not auto-derive values while the base resource has an input error
        if (baseInput.error) {
          continue;
        }
        const delta = res.scales_with.factor * (baseInput.value - baseRes.quota);
        const value = Math.max(res.usage, res.quota + delta); //`delta` may be negative!
        newState.inputs[res.name] = {
          value: value,
          text: (new Unit(res.unit)).format(value, { ascii: true }),
        };

      }
    }

    this.setState(newState);
  };

  toggleFollowing = () => {
    //We call triggerParseInputs() to reset follower resources to their
    //automatic values, and delegate our own state change to it as well because
    //our state update would not be seen (and thus overwritten) by
    //triggerParseInputs() otherwise.
    this.triggerParseInputs({ isFollowing: !this.state.isFollowing });
  };

  close = (e) => {
    if (e) { e.stopPropagation(); }
    this.setState({show: false});
    setTimeout(() => this.props.history.replace('/'), 300);
  }

  handleSubmit = (values) => {
    this.close();
  }

  render() {
    //these props are passed on to the ProjectResource children verbatim
    const forwardProps = {
      flavorData: this.props.flavorData,
      metadata:   this.props.metadata,
    };

    const { category, categoryName } = this.props;

    const hasErrors = Object.entries(this.state.inputs || {}).some(([_, v]) => v.error);

    //NOTE: className='resources' on Modal ensures that plugin-specific CSS rules get applied
    return (
      <Modal className='resources' backdrop='static' show={this.state.show} onHide={this.close} bsSize="large" aria-labelledby="contained-modal-title-lg">
        <Modal.Header closeButton>
          <Modal.Title id="contained-modal-title-lg">
            Edit Project Quota: {t(categoryName)}
          </Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <div className='row edit-quota-form-header'>
            <div className='col-md-offset-6 col-md-6'><strong>New Quota</strong></div>
          </div>
          {this.state.inputs && category.resources.sort(byUIString).map(res => (
            <ProjectResource
              key={res.name} resource={res} {...forwardProps}
              edit={this.state.inputs[res.name]}
              isFollowing={this.state.isFollowing && this.state.canFollow[res.name]}
              handleInput={this.handleInput}
              triggerParseInputs={this.triggerParseInputs}
            />
          ))}
        </Modal.Body>
        <Modal.Footer>
          { this.state.isFollowing !== null && <Button
            onClick={this.toggleFollowing}>
              <i className={this.state.isFollowing ? 'fa fa-lg fa-unlink' : 'fa fa-lg fa-link' } />
              {this.state.isFollowing ? ' Unlink' : ' Link' }
            </Button>
          }
          <Button bsStyle='primary' onClick={this.submit} disabled={hasErrors}>Check</Button>
          <Button onClick={this.close}>Cancel</Button>
        </Modal.Footer>
      </Modal>
    );
  }
}
